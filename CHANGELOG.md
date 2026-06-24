# Changelog

> When cutting a new release, add a `## v<version>` section here (matching `PLUGIN_VERSION` in `plugin.js` exactly). The release workflow automatically pulls the matching section into the GitHub Release notes.

## v2.3.1
- **Auto-Join**: Save on a Task/Event edit form now automatically adds you to Subscribers/Invitees if you're not already on it. No-op if you're already on it, and never blocks Save if detection fails.
- **Locate**: selecting text in the preview highlights and scrolls to the matching source in the editor (toggle with "⇄ Locate"), with LaTeX-aware matching.
- **Auto Update toggle**: optionally disable live preview re-rendering and refresh manually with the floating "↻ Update" button instead.
- **Minimap hierarchy hover**: hovering a top-level minimap item reveals its sub-headings for direct navigation; edit-mode headings are now read from the editor's `=` syntax in document order.
- Fix: the minimap now stays in sync after "Show Older Changes" loads more comments, or after a Calendar event's AJAX preview refresh replaces the preview pane.
- Clicking the toolbar logo navigates to the Phabricator homepage.
- Smoother syntax-highlight backdrop scrolling via a compositor-thread animation.
