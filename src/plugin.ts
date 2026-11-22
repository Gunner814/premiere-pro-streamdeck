import streamDeck from "@elgato/streamdeck";

import { TimelineDial } from "./actions/timeline-dial";
import { keys } from "./keys";

// Last-resort nets so a stray error logs instead of taking the plugin process down.
process.on("uncaughtException", (err) => {
	streamDeck.logger.error(`Uncaught exception: ${err.stack ?? err.message}`);
});
process.on("unhandledRejection", (reason) => {
	streamDeck.logger.error(`Unhandled rejection: ${String(reason)}`);
});
process.on("exit", () => keys.dispose());

streamDeck.logger.setLevel("info");

streamDeck.actions.registerAction(new TimelineDial());

streamDeck.connect();
