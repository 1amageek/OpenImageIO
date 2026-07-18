import { test, expect, type Page } from "@playwright/test";

// OpenImageIO E2E — Swift Testing ABI v0 drives the assertions.
//
// The WASM module's `setup()` encodes a known 4x4 RGBA pattern to PNG
// via OpenImageIO, then decodes it back and stashes both buffers in
// module state. BrowserTestRunner (from swift-wasm-testing) then spawns
// the Swift Testing ABI v0 entry point; every `@Test` function inspects
// the captured state and streams records into `window.__wasm_tests`.
//
// This spec is a thin driver: wait for completion, dump records for
// diagnostics, fail iff any @Test recorded an issue (or the runner threw).

interface WasmTestsState {
    done: boolean;
    success: boolean;
    error: string | null;
    records: string[];
}

async function waitForWasmTests(page: Page): Promise<WasmTestsState> {
    await page.waitForFunction(
        () => {
            const t = (window as unknown as { __wasm_tests?: { done?: boolean } }).__wasm_tests;
            return !!t && t.done === true;
        },
        null,
        { timeout: 45_000 }
    );
    return await page.evaluate((): WasmTestsState => {
        const t = (window as unknown as { __wasm_tests: WasmTestsState }).__wasm_tests;
        return {
            done: t.done,
            success: t.success,
            error: t.error,
            records: t.records,
        };
    });
}

test("Swift codecs roundtrip under WASM and browser decoders accept their output", async ({ page }) => {
    page.on("console", (msg) => console.log(`[page:${msg.type()}]`, msg.text()));
    page.on("pageerror", (err) => console.error("[pageerror]", err.message));

    await page.goto("/");
    const state = await waitForWasmTests(page);

    console.log("----- swift-testing records -----");
    const failureMessages: string[] = [];
    for (const raw of state.records) {
        try {
            const rec = JSON.parse(raw);
            console.log(JSON.stringify(rec));
            if (rec.kind === "event" && rec.payload?.kind === "issueRecorded") {
                const msg = rec.payload?.issue?.sourceContext?.message
                    ?? rec.payload?.messages?.map((m: { text: string }) => m.text).join("; ")
                    ?? raw;
                failureMessages.push(typeof msg === "string" ? msg : JSON.stringify(msg));
            }
        } catch {
            console.log("[unparsable]", raw);
        }
    }
    console.log("---------------------------------");
    console.log(`runner: success=${state.success} error=${state.error ?? "null"} records=${state.records.length}`);

    expect(state.error, "runner must not throw").toBeNull();
    expect(
        state.success,
        `swift-testing reported failures. Issues:\n${failureMessages.join("\n")}`
    ).toBe(true);

    const decodedFormats = await page.evaluate(async () => {
        const names = ["png", "jpeg", "gif", "bmp"] as const;
        const results: Record<string, { width: number; height: number }> = {};
        const globals = window as unknown as Record<string, unknown>;
        for (const name of names) {
            const base64 = globals[`__oiio_${name}_base64`];
            if (typeof base64 !== "string") {
                throw new Error(`Swift did not publish ${name} output`);
            }
            const binary = atob(base64);
            const bytes = Uint8Array.from(binary, (character) => character.charCodeAt(0));
            let bitmap: ImageBitmap;
            try {
                bitmap = await createImageBitmap(new Blob([bytes]));
            } catch (error) {
                throw new Error(`${name} browser decode failed: ${String(error)}`);
            }
            results[name] = { width: bitmap.width, height: bitmap.height };
            bitmap.close();
        }
        return results;
    });

    for (const [format, dimensions] of Object.entries(decodedFormats)) {
        expect(dimensions, `${format} must decode in Chromium`).toEqual({ width: 4, height: 4 });
    }
});
