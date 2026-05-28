
Issues 1, 2, 3 — reconnection / Connect button
chat_screen.dart:1408 — added canQuickConnect flag (verified contact with known address, no secure channel).
chat_screen.dart:2000-2058 — composer button now becomes Connect (with wifi_tethering_outlined icon) when offline, dispatching PeerConnectIntent over the existing LAN signaling path. Works symmetrically on initiator (A) and responder (W) since both sides hold each other's verified contact + lastKnownAddress after the first exchange.
Issue 4 — button label
Send Secure Message → Send in the same composer block.
Issue 5 — burn-after-read actually deletes

peer_session_controller.dart:685 — in markMessagesRead, after sending the read receipt, deletes the received message locally if burnAfterRead is set.
peer_session_controller.dart:1630 — in _handleReceiptEnvelope, when an outgoing message's read receipt arrives, deletes the sender's copy if burnAfterRead is set. (The previous implementation only set a 10-min TTL backstop with no delete-on-read.)
Issue 6 — spec review
The remaining items in GungChat-Plan-Spec.md (E2E encryption, voice/video, LAN-first transport, 320p video, QR exchange, presence, reactions, replies, edits) are already implemented per the existing test suite and prior sessions. The two genuine spec gaps surfaced by your bug reports — reconnect UX and F4 burn-after-read — are the ones fixed above. If you want me to do a deeper line-by-line spec audit against current code, say the word.
8 bundled SVG stickers — colored rounded squares with an OS emoji glyph drawn on top (so they look like stickers but don't require pixel art):
 Auto-scroll: done
Chat screen translation (Scope A, machine-quality) is complete across all 5 locales (en, zh, zh_TW, es, fr).