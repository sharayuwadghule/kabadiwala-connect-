# Kabadiwala Connect - Progress Tracker

This document tracks the implementation progress, simulated features, and user flows for the Kabadiwala Connect Flutter application.

## 📱 User Flows

### 1. Collector Flow (Primary)
The complete end-to-end flow for scrap collectors:
1. **Onboarding**: Register with a 10-digit mobile number and select language (Marathi, Hindi, or English).
2. **Dashboard**: View recent lots, earnings, and current seeded prices.
3. **Capture**: Start a Batch/Single lot and capture photos (camera or gallery with compression).
4. **Identification**: AI suggestion via secure Roboflow backend, or manual material selection/correction.
5. **Review & Safety**: Confirm material categories. Acknowledge safety warnings (e.g., Battery, CRT) with Text-to-Speech support.
6. **Weight & Value**: Enter weights for materials to generate an estimated price.
7. **Lot Generation**: Lot is finalized with GPS coordinates and a scannable QR code.
8. **Recycler Match**: Rule-based matching recommends compatible recyclers based on distance and rates.
9. **Handover**: Transfer to recycler, confirm final weights and cash/digital payment preference.
10. **Ledger**: Transaction is saved to the persistent local ledger.

### 2. Recycler Flow
1. **Recycler Dashboard**: View incoming lots and weight/value metrics.
2. **Receiving**: Open an incoming lot (or scan QR - *UI only*).
3. **Verification**: Enter the final verified weight and value.
4. **Anomaly Check**: Rule-based check alerts if values fall outside expected ranges.
5. **Confirmation**: Confirm receipt and mark payment status.

### 3. Offline & Sync Flow
1. **Local Workflow**: Collector generates lots offline.
2. **Pending Sync**: Lots are stored locally and marked as pending.
3. **Reconnection**: App retries sync when internet is restored.
4. **Upload**: Data is sent to the remote repository.
5. **Synced**: Local lot is marked as synced (prevents duplicate uploads).

---

## ✅ Implemented Features (Completed)
- [x] **Core UI & Navigation**: Native responsive shell (capped at 480px on desktop/web) with a 3-language workflow.
- [x] **Camera & Image Handling**: `image_picker` integration with automatic image resizing and compression.
- [x] **AI Integration**: Secure multipart integration with `/api/detect` for Roboflow inference.
- [x] **Material System**: Seven primary categories with specific hazards, tips, and recovery values.
- [x] **Safety & Accessibility**: Blocking warnings for hazardous materials, supported by `flutter_tts` for spoken instructions.
- [x] **Traceability**: Digital lot generation with ID format (`KWC-2026-####`), device GPS tagging, and standardized QR code generation.
- [x] **Local Persistence**: `SharedPreferences` powered ledger for offline storage and tracking.
- [x] **Deduplication**: Sync queue prevents duplicate uploads and blocks duplicate receipts.

---

## 🚧 Simulated / Work in Progress (Demo Features)
These features are currently rule-based, mocked, or simulated and require backend/third-party integration for production:

- [ ] **Remote Backend**: Currently using a deduplicating `DemoRemoteRepository`. Needs authenticated API for real remote sync.
- [ ] **Live Market Prices**: Currently using seeded static rates and 7-day history graphs. Needs a verified live price feed.
- [ ] **Verified Recyclers**: Recycler matching is based on local rule-based scoring. Needs an authoritative registry (e.g., CPCB/SPCB).
- [ ] **Payment Gateway**: Payment preference (Cash vs. UPI) is a UI toggle. **No actual money transfer is processed**.
- [ ] **Camera QR Scanner**: QR payloads resolve locally, but the live camera scanning integration for recyclers to scan physical devices is pending.
- [ ] **Production ML Classification**: Model depends on deployed Roboflow dataset; currently requires actual field image validation.

---

## 🚀 Recommended Next Steps
1. **Model Validation**: Configure and validate the actual Roboflow model/classes using real field images.
2. **API Replacement**: Swap out `DemoRemoteRepository` with the authenticated collector/lot production APIs.
3. **Registry Integration**: Import verified recycler registrations and live price feeds.
4. **QR Integration**: Implement the camera QR scanner for deep-linkable server lot routes.
5. **Field Testing**: Run physical field studies with at least two collectors to test camera hardware, GPS denial states, offline reconnects, and low-memory behavior.
