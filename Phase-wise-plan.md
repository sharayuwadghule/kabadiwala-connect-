KABADIWALA CONNECT — FINAL PHASE-WISE BUILD PLAN
PHASE 0 — Product foundation + architecture

Goal: Make sure the architecture itself satisfies the PS before adding features.

0.1 Define the three user types
INFORMAL SIDE
├── Individual Collector / Kabadiwala
└── Small Aggregator

FORMAL SIDE
└── Authorized Recycler

PLATFORM
└── Admin / verification layer

Don't create separate apps.

Use role-based access:

accountType
├── informal_collector
├── aggregator
└── authorized_recycler
0.2 Define the core transaction object

Everything should revolve around the Lot.

Lot
├── Unique Lot ID
├── Material
├── Photos
├── Approx. weight
├── Estimated value
├── Market range
├── Recycler offers
├── Selected recycler
├── Agreed price
├── Final weight
├── Final price
├── Payment status
├── GPS
├── timestamps
├── Collector
├── Recycler
├── Handover status
└── Processing status

This is the foundation for your dataset and traceability.

PHASE 1 — Collector-first, low-literacy interface

Goal: Satisfy the PS's accessibility requirements before worrying about advanced AI.

The PS specifically requires Marathi + Hindi minimum, a genuinely usable interface for limited literacy, and pictorial/audio safety guidance.

1.1 Languages

Minimum:

Marathi
Hindi
English

Don't just translate text.

Design around:

Icon + short label + optional voice

Example:

📷
फोटो काढा

[🔊 ऐका]
1.2 Low-literacy UX

Use:

large buttons
icons
minimal text
visual categories
colour/status indicators used consistently
audio instructions
number-heavy rather than paragraph-heavy screens
one primary action per screen

Avoid:

long forms
technical terminology
dense tables
unnecessary registration fields
1.3 Collector onboarding

Ask only:

Name / identifier
Mobile number
Language
Operating area
Collector / Aggregator

The PS explicitly says the collector dataset should be minimal and unnecessary personal information should be avoided.

PHASE 2 — Genuine offline-first architecture

This should become a real technical property, not just a presentation claim.

The PS explicitly requires core activities to work offline and synchronize when connectivity returns.

2.1 Offline-capable actions

The collector should be able to do these with zero internet:

Create lot
↓
Capture photo
↓
Select/correct material
↓
Enter weight
↓
View cached price information
↓
Generate Lot ID
↓
Generate QR
↓
Save transaction locally
2.2 Sync engine

When connectivity returns:

LOCAL DATABASE
      ↓
Pending Sync Queue
      ↓
Internet detected
      ↓
Upload
      ↓
Server validation
      ↓
Sync success
      ↓
Mark synced
2.3 Conflict handling

Implement:

duplicate prevention
retry
failed sync status
timestamp
server/local version
idempotent transaction IDs

You already have some deduplication — keep it.

2.4 Important UX

Show:

📴 Offline
3 lots saved locally

Last synced:
Today, 10:42 AM

Then:

🌐 Connected

3 lots ready to sync

✓ 3 synced

That will make your offline-first claim demonstrable.

PHASE 3 — Material capture + classification

You already have most of this.

Flow
CAPTURE
↓
PHOTO
↓
AI SUGGESTION
↓
COLLECTOR CONFIRMS / CORRECTS
↓
MATERIAL CATEGORY
↓
APPROX WEIGHT
↓
SAFETY FLAG
Important change

Don't present AI as:

"AI determines the exact material/mineral."

Present it as:

AI-assisted material/category classification.

The PS itself describes image/category/weight/location/history as inputs for AI/ML features such as classification, valuation and matching where sufficient data exists.

Categories

At minimum, cover the PS examples:

CRT
LCD panels
PCB
cables
batteries
motors/magnet-bearing assemblies
mixed plastics
PHASE 4 — Safety intelligence

You already have this.

Make it contextual.

Example

Battery detected:

⚠ BATTERY

DO NOT
🔥 Burn
🔨 Crush
✂ Cut

SAFE HANDLING
Keep away from heat
Avoid puncturing

🔊 Listen

For CRT:

⚠ CRT

Risk:
Glass / hazardous components

Do not break manually.
Use authorized handling.

The PS specifically asks for pictorial/audio safety guidance covering hazardous practices including improper burning/opening and safe battery/CRT handling.

PHASE 5 — Price Intelligence

This should be substantially stronger than your current seeded price graph.

Build three separate concepts
A. Market Range
PCB
Nashik

Current observed range
₹180–₹225/kg
B. Recycler Offers
Recycler A
₹210/kg

Recycler B
₹220/kg

Recycler C
₹205/kg
C. Final Transaction Price
Agreed
₹220/kg

Final
₹215/kg

This distinction is extremely important.

The PS requires a price dataset containing category, location, date, buying price, unit, market range and recycler/aggregator offered price, plus historical information.

Historical view
7 days
30 days
90 days

But only display meaningful trends when you have enough data.

PHASE 6 — Authorized Recycler Registry

This is one of your biggest remaining gaps.

Create:

Recycler Dataset

Each recycler:

Name
Facility location
Accepted materials
Authorization details
Authorization status
Contact
Offered rates
Pickup availability
Service area

These are explicitly required dataset fields in the PS.

Recycler profile
XYZ Recycling

✓ Authorization verified

Accepted:
PCB
Cable
Battery

Service area:
Nashik

Pickup:
Available

Current PCB offer:
₹215/kg

Don't just show "verified" without knowing the source of verification.

PHASE 7 — Recycler Marketplace

This is one of your highest-priority builds.

Instead of:

"Here is your recommended recycler."

show:

AVAILABLE OFFERS

XYZ Recycling
₹215/kg
12 km
Pickup ✓
Verified ✓

ABC Recycling
₹220/kg
18 km
Pickup ✗
Verified ✓

PQR Recycling
₹205/kg
7 km
Pickup ✓
Verified ✓

The PS says recycler matching should consider:

location
material category
offered rate
pickup availability
authorization status.

So implement exactly that.

Matching score

Initially rule-based:

Authorization
+ Material compatibility
+ Price
+ Distance
+ Pickup
+ Service area

Later, if sufficient data exists:

ML-based recommendation.

PHASE 8 — Recycler-side interface

This is currently missing and is mandatory in the expected outcome.

Build:

Recycler Dashboard
Incoming Lots
Offers
Accepted Lots
Completed Handovers
Payments
Processing
Analytics
Profile
Incoming lot
KWC-2026-0482

PCB
18 kg approx.

Photos
Location
Collector
Safety flags
Expected value

[Make Offer]
[Accept]
[Reject]
Make Offer
Offer:
₹____ / kg

Pickup:
Yes / No

Pickup date:
____

Minimum quantity:
____

[Submit Offer]

This changes the system from a static marketplace into a two-sided transaction platform.

PHASE 9 — Digital Transaction Agreement

Before physical handover:

LOT #KWC-2026-0482

Material:
PCB

Approx. weight:
18 kg

Recycler:
XYZ Recycling

Agreed rate:
₹215/kg

Payment:
Cash

Handover:
Pickup

Collector:
✓ Accepted

Recycler:
✓ Accepted

Then:

Agreement locked

This creates:

Offer → Agreement → Handover

Don't call it a legally binding contract unless legally validated.

PHASE 10 — Token-based traceability

This should become one of your central features.

The token isn't simply a QR.

Every lot gets:
KWC-2026-0482

That ID persists throughout its lifecycle.

Token contains/links to
Photos
Material
Approx. weight
Final weight
Price
Recycler
Collector
GPS
Collection timestamp
Handover timestamp
Payment
Recycler confirmation
Processing status

The PS explicitly requires a digital/verifiable handover record containing photographs, weight, timestamp, GPS/location and a unique reference that can be confirmed by the recycler.

PHASE 11 — Complete material handover

This is where the token becomes meaningful.

Collector
LOT CREATED
↓
OFFER ACCEPTED
↓
AGREEMENT ACCEPTED
↓
READY FOR HANDOVER
↓
HANDED OVER
↓
AWAITING RECYCLER CONFIRMATION
↓
COMPLETED ✓
Recycler
INCOMING
↓
RECEIVED
↓
VERIFY MATERIAL
↓
VERIFY WEIGHT
↓
CONFIRM PRICE
↓
CONFIRM PAYMENT
↓
CONFIRM HANDOVER

Only after recycler confirmation:

Handover = COMPLETED

PHASE 12 — Payment + earnings ledger

The PS specifically requires an understandable earnings ledger and says cash transactions must remain supported while digital payment is optional.

So:

Payment method

○ Cash
○ UPI

Do not require a payment gateway.

Earnings
THIS MONTH

Completed sales
₹18,450

Pending
₹2,100

Transactions
14

And individual records:

PCB
18kg

₹3,870

Cash
Paid ✓
PHASE 13 — Complete token lifecycle

Now connect everything:

CREATE
  ↓
PRICE
  ↓
OFFERS
  ↓
AGREEMENT
  ↓
HANDOVER
  ↓
RECYCLER CONFIRMATION
  ↓
PAYMENT
  ↓
PROCESSING STATUS

Your token becomes the persistent identity of the lot.

Example
KWC-2026-0482

✓ Created
✓ Offer accepted
✓ Agreement completed
✓ Handover completed
✓ Payment completed
● Processing

If recycler confirms processing:

✓ Received
✓ Sorted
✓ Processed

Don't automatically claim downstream recycling merely because the token exists.

PHASE 14 — Aggregator workflow

This is a valuable domain-specific extension.

Collector A ─┐
Collector B ─┼→ Aggregator → Recycler
Collector C ─┘

Aggregator can:

Receive Lots
A — PCB — 8kg
B — PCB — 12kg
C — PCB — 5kg
Consolidate
CONSOLIDATED LOT

25kg PCB

Source:
#0482
#0487
#0491

The system preserves the relationship:

Source Lots → Consolidated Lot → Recycler

This gives you traceability even when the real-world chain includes an intermediary.

PHASE 15 — Recycler reliability

Don't rank only by price.

Show factual indicators:

XYZ Recycling

Authorization ✓
Pickup ✓

48 completed transactions
94% offer/final-price consistency
100% payment completion

Only display metrics that your platform actually has enough data to calculate.

This can eventually support better recycler matching.

PHASE 16 — Transaction anomaly detection

This is where your PS-required ML/data component becomes meaningful.

Start with rules:

Expected:
₹180–₹220/kg

Recycler offer:
₹420/kg

⚠ Unusual price

Or:

Approx weight:
20kg

Final weight:
9kg

⚠ Large weight difference

Then, once sufficient transaction data exists:

statistical anomaly detection → ML

The PS specifically identifies abnormal/inconsistent transaction values as a potential AI/ML use case.

PHASE 17 — Government / EPR / Scheme Access Layer

This is the institutional gap feature we discussed.

Don't make unsupported claims such as:

"Government pays the kabadiwala through our app."

Instead:

Formalization & Scheme Navigator
For collector
FORMAL RECYCLING ACCESS

Your records
✓ 12 completed handovers
✓ ₹18,450 recorded earnings

Relevant programs
→ Program / initiative
→ Eligibility
→ Documents
→ How to apply
→ Official authority
For recycler
FORMALIZATION

Registration
EPR information
Record requirements
Applicable support
Applicable schemes
Compliance guidance

Every scheme should have:

authority
eligibility
documents
application process
official source
last verified date
Important

Your platform is the:

information + record + navigation layer

—not the government scheme itself.

And actual EPR certificate generation should remain with the applicable official system unless you have a legitimate integration.

This directly addresses the PS's stated informational and institutional gap.

PHASE 18 — Material journey / downstream visibility

After handover:

COLLECTED
↓
AGGREGATED
↓
RECYCLER RECEIVED
↓
SORTED
↓
PROCESSED
↓
RECOVERED / SENT DOWNSTREAM

Only show downstream events when supported by recycler-confirmed data.

This gives your presentation a powerful visual:

"Where did this material go?"

Instead of only:

"Transaction completed."

PHASE 19 — Dataset architecture

This is not optional.

The PS explicitly requires structured datasets and says teams should demonstrate how the dataset is generated, stored, validated, updated and used, rather than treating it as a static database.

Create these datasets:

1. Material Dataset
category
subcategory
description
image
weight
condition
source
estimated value
2. Price Dataset
material
location
date
buying price
selling/quoted price
unit
market range
recycler
historical price
3. Recycler Dataset
name
location
accepted materials
authorization
contact
rate
pickup
service area
4. Transaction Dataset
lot ID
collector
material
weight
quoted price
final price
recycler
collection location
handover location
date/time
payment status
transaction status
5. Traceability Dataset
lot ID
photos
weight
timestamp
GPS
handover reference
recycler confirmation
subsequent status
6. Collector Dataset

Keep minimal:

collector ID
language
general area
transaction history
earnings history
7. AI/ML Dataset
image
material
weight
price
location
transaction

with:

source + size + quality + limitations

documented.

PHASE 20 — Data flywheel

Now make the dataset actively useful.

FIELD TRANSACTIONS
        ↓
STRUCTURED DATA
        ↓
PRICE INTELLIGENCE
        ↓
RECYCLER MATCHING
        ↓
ANOMALY DETECTION
        ↓
BETTER TRANSACTIONS
        ↓
MORE DATA

This is a much stronger technical story than simply:

"We have Firebase."

PHASE 21 — AI/ML maturity ladder

Don't force ML everywhere.

Level 1 — Rules
Material → compatible recyclers
Price → market range
Weight difference → warning
Level 2 — Statistics
Historical prices
Average offers
Price trends
Transaction variance
Level 3 — ML

Only when data supports it:

Image → material classification

Material + weight + location + history
→ approximate valuation

Lot + recycler history
→ recycler recommendation

Transaction features
→ anomaly detection

The PS itself says AI/ML should be used wherever sufficient training data is available.

PHASE 22 — Entry-level Android optimization

This should be a technical acceptance criterion.

Target

Design for:

low RAM
limited storage
slower CPU
unstable network
inexpensive Android devices
Do
compress photos before storage/upload
resize images
lazy-load images
cache only necessary data
avoid large animations
avoid unnecessary packages
use local database
paginate transaction history
minimize background work
sync intelligently
keep ML model small
use TFLite if deploying on-device
avoid downloading huge datasets
Measure

Don't just say:

"Small app."

Record:

APK size: ___ MB
RAM during normal workflow: ___ MB
Offline storage: ___ MB
Photo compressed from ___ → ___

That gives you evidence during judging.

PHASE 23 — Field research

The PS requires field research involving at least two working scrap collectors or aggregators.

Ideally:

2+ collectors/aggregators + 1+ recycler

Observe:

Material flow
Source
→ Collector
→ Aggregator
→ Recycler
→ Processing
Money flow
Who pays whom?
When?
How is price decided?
Information flow
Who knows the market price?
Who knows recycler rates?
Record flow
Paper?
WhatsApp?
Excel?
Nothing?

Then validate your prototype against reality.

PHASE 24 — Unit economics

The PS explicitly requires comparison of current earnings vs potential platform earnings and an explanation of platform sustainability.

Create a real case from field research:

CURRENT ROUTE

Sale value
− transport
− buyer deductions
− other costs
= collector net earning

Then:

PLATFORM ROUTE

Recycler offer
− transport
− applicable costs
= collector net earning

Compare actual observed numbers, not invented numbers.

Then separately explain:

Platform sustainability

Possible models to investigate:

recycler subscription
B2B service fee
institutional/government deployment
analytics/service layer
transaction fee where commercially acceptable

But don't make the collector bear a fee if that undermines your core proposition without evidence.

PHASE 25 — Live usability demonstration

Your final demo should deliberately prove the PS requirements.

Demo scenario

Start with:

No internet

Collector
Select Marathi
↓
Create lot
↓
Take photo
↓
AI suggestion
↓
Confirm material
↓
Weight
↓
Safety warning
↓
Cached price
↓
Save lot offline

Reconnect.

Sync
↓
Recycler offers appear
↓
Select recycler
↓
Agreement
↓
Token generated

Recycler:

Open incoming lot
↓
Scan QR
↓
Verify material
↓
Enter final weight
↓
Confirm price
↓
Confirm payment
↓
Confirm handover

Collector:

✓ Handover completed
✓ Payment recorded
✓ Earnings updated

Then show:

TOKEN TIMELINE
↓
DATASET RECORD
↓
PRICE HISTORY
↓
RECYCLER HISTORY

That single demo covers a huge portion of the PS.

FINAL PRIORITY MAP
🔴 PHASE A — Must finish first

1. Recycler interface
2. Recycler dataset + authorization
3. Recycler offers
4. Offer comparison
5. Digital Transaction Agreement
6. Complete handover workflow
7. Token-based traceability
8. Final weight + payment + earnings

These turn your current prototype into a real two-sided system.

🟠 PHASE B — Make the solution distinctive

9. Local price intelligence
10. Recycler reliability data
11. Aggregator + consolidation workflow
12. Chain-of-custody timeline
13. Processing status
14. Transaction anomaly detection
15. Government/EPR/Scheme Navigator

This is where your institutional + economic + traceability story becomes much stronger.

🟡 PHASE C — Evidence + compliance with PS

16. Field research
17. Dataset generation pipeline
18. Data validation/anonymization
19. Unit economics
20. Live usability demonstration

These are easy to overlook but are explicitly part of the expected outcome.

🟢 PHASE D — Advanced intelligence

21. Validated Roboflow model
22. Price prediction
23. ML recycler recommendation
24. ML anomaly detection

Only build these deeply when you have enough real data.