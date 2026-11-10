# Future work — more creative collectors

Running list of ideas for making collectors more expressive and robust. Not currently scheduled; drop in here when something surfaces during development so we don't lose it.

## runtime matching semantics

### Collectors depending on other collectors?

Right now every collector runs independently. There's no way to express "only fire this collector when that other collector has just matched."

Concrete uses:
- **Context gating:** an "offer accepted" collector that only runs inside snapshots where an "offer card visible" collector also matches — so we don't mis-fire on stale cached views or unrelated screens.
- **Sequential events:** a "delivery completed" collector that requires a prior "delivery started" match within the same session, enabling derived durations.
- **Scoping:** a parent collector identifies the region of interest (an offer card), and child collectors extract fields only from within that parent's matched subtree. This is a natural way to implement the "all-or-nothing subtree matching" bullet above, and might actually be the cleanest mental model for both problems.

Open questions if we go this way:
- How to express the dependency in the data model — a `parent_collector_id` on `Collector`, or a more general graph of collectors?
- How to evaluate efficiently at runtime — the parent's match would need to narrow the search scope for the children, rather than running every collector against the full snapshot.
- What happens to existing independent collectors? They should continue to work unchanged; dependency is opt-in.

## other notes

- `CONTAINS_TEMPERATURE` and `CONTAINS_VOLUME` are in the `semanticRelations` array but `detectSemanticContent()` has no regexes for them — they're wired but never populated. we dont use these (yet) but I wanted to make them placeholders.

## UX/UI improvements - researcher side

### sort collectors by app 

Right now all collectors are listed in the same order they were created. It would be nice to sort them by the app they were created for. We will have studies where researchers make collectors for multiple apps as part of the same study

### edit collector -- being able to go back to the screen where the collector was created
right now we can just edit the collector name etc, but it would be a nice feature to be able to tap 'edit' and then go back to the screen recording to update the collector later. to do this we need to change how we store screen recordings because right now they're all stored locally on device. to allow other researchers in the same study to edit collectors, screen recording data needs to be stored on the backend

### add an option to each collector to set how frequently to collect that item 

some items like ratings or completion rates or whatever else might not need to be collected every time the app is opened. we should add an option to each collector to set how frequently to collect that item. if a collector is triggered and it hasn't been at least that long since the last collection, it should not be collected again.

## UX / UI improvements - participant side

### add a setting screen with some options:
- toggle on/off showing cards / overlays during data collection 


### show what apps the study is collecting data from in a user-friendly way

### similar to above, sort collectors by app name. require users to expand by app to see what collectors are running for that app.

