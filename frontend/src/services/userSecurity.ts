import type { PushFn } from "../types/constants.types";

export function copyToClipboard(
  text: string | undefined,
  push: PushFn,
  msg: string,
) {
  if (!text) return;

  navigator.clipboard.writeText(text);
  push(msg, "success");
}

export function maskLink(link?: string) {
  if (!link) return "";

  try {
    const cleaned = link.replace("naive+", "");
    const url = new URL(cleaned);

    const auth = "***";
    const hostParts = url.hostname.split(".");

    let maskedHost = "***";

    if (hostParts.length >= 2) {
      maskedHost = `${hostParts[0]}.***`;
    }

    return `naive+https://${auth}@${maskedHost}${
      url.port ? `:${url.port}` : ""
    }`;
  } catch {
    return "hidden";
  }
}
