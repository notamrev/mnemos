import * as assert from "assert";
import { shouldCaptureFile, tagsForLanguage, shouldCaptureCommand } from "../filterEngine";

describe("shouldCaptureFile", () => {
  it("allows normal workspace files", () => {
    assert.ok(shouldCaptureFile("/Users/alice/project/src/AuthService.swift"));
  });
  it("rejects node_modules paths", () => {
    assert.ok(!shouldCaptureFile("/Users/alice/project/node_modules/lodash/index.js"));
  });
  it("rejects .git paths", () => {
    assert.ok(!shouldCaptureFile("/Users/alice/project/.git/COMMIT_EDITMSG"));
  });
  it("rejects build output paths", () => {
    assert.ok(!shouldCaptureFile("/Users/alice/project/dist/bundle.js"));
  });
});

describe("tagsForLanguage", () => {
  it("maps swift → ['swift']", () => {
    assert.deepStrictEqual(tagsForLanguage("swift"), ["swift"]);
  });
  it("maps typescript → ['typescript']", () => {
    assert.deepStrictEqual(tagsForLanguage("typescript"), ["typescript"]);
  });
  it("maps typescriptreact → ['typescript']", () => {
    assert.deepStrictEqual(tagsForLanguage("typescriptreact"), ["typescript"]);
  });
  it("returns [] for unknown language", () => {
    assert.deepStrictEqual(tagsForLanguage("plaintext"), []);
  });
});

describe("shouldCaptureCommand", () => {
  it("captures git commit", () => {
    assert.ok(shouldCaptureCommand("git commit -m 'feat: add login'"));
  });
  it("captures npm run build", () => {
    assert.ok(shouldCaptureCommand("npm run build"));
  });
  it("rejects short commands", () => {
    assert.ok(!shouldCaptureCommand("ls"));
  });
  it("rejects cd", () => {
    assert.ok(!shouldCaptureCommand("cd /Users/alice/project"));
  });
  it("rejects cat", () => {
    assert.ok(!shouldCaptureCommand("cat README.md"));
  });
  it("rejects git status (not a signal command)", () => {
    assert.ok(!shouldCaptureCommand("git status"));
  });
});
