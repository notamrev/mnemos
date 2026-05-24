import * as http from "http";

export interface CapturePayload {
  source: string;
  content: string;
  tags: string[];
  metadata?: Record<string, string>;
}

export function send(payload: CapturePayload, port: number): void {
  const body = JSON.stringify(payload);
  const req = http.request(
    {
      hostname: "127.0.0.1",
      port,
      path: "/capture",
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Content-Length": Buffer.byteLength(body),
      },
    },
    () => {} // response handler — fire and forget
  );
  req.on("error", () => {}); // silently no-op if Mnemos isn't running
  req.write(body);
  req.end();
}
