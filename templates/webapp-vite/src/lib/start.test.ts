import { expect, test, vi } from "vitest";
import { endStart, holdStart } from "./start";

test("the app holds the copy's start once and lets it go once, however often it asks", () => {
  const sbStart = { hold: vi.fn(), release: vi.fn() };
  Object.assign(window, { sbStart });
  endStart(); // nothing held yet
  holdStart();
  holdStart();
  endStart();
  endStart(); // React runs an effect twice in its strict mode
  expect(sbStart.hold).toHaveBeenCalledTimes(1);
  expect(sbStart.release).toHaveBeenCalledTimes(1);
});

test("without the copy's start (a unit test, a page without it) nothing fails", () => {
  Object.assign(window, { sbStart: undefined });
  expect(() => {
    holdStart();
    endStart();
  }).not.toThrow();
});
