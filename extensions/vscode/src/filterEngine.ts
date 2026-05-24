import * as path from "path";

const SKIP_DIRS = new Set([
  "node_modules", ".git", "dist", "build", "out", ".next",
  ".nuxt", "coverage", "__pycache__", ".venv", "vendor",
]);

const LANGUAGE_TAG: Record<string, string> = {
  swift: "swift", objective_c: "objc", objc: "objc",
  typescript: "typescript", typescriptreact: "typescript",
  javascript: "javascript", javascriptreact: "javascript",
  python: "python", go: "go", rust: "rust",
  java: "java", kotlin: "kotlin", cpp: "cpp", c: "c",
  ruby: "ruby", php: "php", cs: "csharp", sh: "shell",
};

// Terminal commands worth capturing
const SIGNAL_PREFIXES = [
  "git commit", "git push", "git merge", "git rebase",
  "npm run", "yarn ", "pnpm run", "npx ",
  "make ", "cargo ", "swift build", "swift test",
  "xcodebuild", "fastlane",
];

export function shouldCaptureFile(fsPath: string): boolean {
  const parts = fsPath.split(path.sep);
  return !parts.some((p) => SKIP_DIRS.has(p));
}

export function tagsForLanguage(languageId: string): string[] {
  const tag = LANGUAGE_TAG[languageId.toLowerCase()];
  return tag ? [tag] : [];
}

export function shouldCaptureCommand(command: string): boolean {
  const trimmed = command.trim();
  if (trimmed.length < 10) return false;
  return SIGNAL_PREFIXES.some((prefix) => trimmed.startsWith(prefix));
}
