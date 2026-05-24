import * as vscode from "vscode";
import * as path from "path";
import { send } from "./captureClient";
import { shouldCaptureFile, tagsForLanguage, shouldCaptureCommand } from "./filterEngine";

function config() {
  return vscode.workspace.getConfiguration("mnemos");
}

function port(): number {
  return config().get<number>("serverPort", 40842);
}

function projectName(fsPath: string): string {
  return vscode.workspace.getWorkspaceFolder(vscode.Uri.file(fsPath))?.name ?? "unknown";
}

function captureFile(doc: vscode.TextDocument, verb: "Opened" | "Saved"): void {
  if (!config().get<boolean>("enabled", true)) return;
  if (doc.uri.scheme !== "file") return;
  if (!shouldCaptureFile(doc.uri.fsPath)) return;

  const filename = path.basename(doc.uri.fsPath);
  const tags = tagsForLanguage(doc.languageId);

  send(
    {
      source: "vscode",
      content: `${verb} ${filename}`,
      tags,
      metadata: {
        file_path: doc.uri.fsPath,
        project: projectName(doc.uri.fsPath),
        language: doc.languageId,
      },
    },
    port()
  );
}

export function activate(context: vscode.ExtensionContext): void {
  context.subscriptions.push(
    vscode.workspace.onDidOpenTextDocument((doc) => captureFile(doc, "Opened")),
    vscode.workspace.onDidSaveTextDocument((doc) => captureFile(doc, "Saved"))
  );

  // Terminal capture — opt-in only
  context.subscriptions.push(
    vscode.window.onDidExecuteTerminalCommand?.((event) => {
      if (!config().get<boolean>("captureTerminal", false)) return;
      if (!config().get<boolean>("enabled", true)) return;
      const cmd = event.commandLine?.trim() ?? "";
      if (!shouldCaptureCommand(cmd)) return;
      send(
        {
          source: "vscode-terminal",
          content: cmd,
          tags: ["terminal"],
          metadata: { exit_code: String(event.exitCode ?? "") },
        },
        port()
      );
    }) ?? { dispose: () => {} }
  );
}

export function deactivate(): void {}
