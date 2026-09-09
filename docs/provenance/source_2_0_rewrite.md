# Source 2.0 draft-history rewrite

This record maps the unpublished Source 2.0 draft onto the owner-approved
modernization branch. Local `main` at
`3d9f56e5eae3a3d7edfa4186081918e3e522d7e2` was the immutable base. The rewrite
preserves the established architectural boundaries and prevents modified files
from creating new historical copies of legacy review metadata.

| Previous commit | Replacement commit | Scope | Reason |
| --- | --- | --- | --- |
| `0d7875881571dcf073acc7e2baad6c4f00f28a4c` | `b162e5e9e6a05d0d628828efebda7998d22d510c` | Correct the checksum-error documentation link. | Preserve the one-file change while recording the current co-author accurately. |
| `3bb9ca0ebbc492070ef4ce1eee7a92150bba18a8` | `9ef65d570ae7118cce74aa35d3ab983fd7a0202b` | Reconstruct the Z80 driver and sound data. | Replay the complete atomic subsystem change onto the approved base. |
| `e911d088d9c9af49cdeae0878552855921d568c0` | `9fcfcfc63de524a7b07c05a72a9a205105633796` | Isolate content authoring. | Preserve the build boundary and zero-edit identity evidence. |
| `fc9b3f856390571589d2d5d5f388d1967e335aee` | `c9f5e0eda5bfbca5d5933ac75fd93d7751068ec2` | Add level authoring and Level Studio. | Preserve one complete editor-model vertical slice. |
| `8227525f7b3635c1beb99330c843f7f4703188d2` | `8b012f6ad546c1d1ed3e19d3527c71252a4c84d2` | Add graphics authoring and adopt project-owned release metadata. | Keep the codec, model, GUI, and test boundary while removing legacy provenance before changed files create new draft blobs. |
| `7d16bd7f68161d660f77d9ad2773ab850c9d0c15` | `d07b49bb0d4b354a47a2bc956d13f898ce58bbad` | Add music, SFX, and FM voice authoring. | Preserve the semantic sound-authoring boundary. |
| `d51297d3a15364ef6a2a649dd3b921cc9b31b5d1` | `b75e67b65a899a058afd5134b0c8062515240fe1` | Define the Source 2.0 project gate. | Preserve the first complete machine-readable acceptance boundary. |
| `ddf6a5c9537ee553e435db1588fc44c570c1df66` | `ee536136572abd99643913e23ca4e94f85d8aac3` | Organize assembly by semantic owner. | Preserve the address-safe source reorganization as one reviewable change. |
| `d838db42acc3855c1419a902ffdaf60c0304a048` | `0111bf7083a22e4802a1d465c37e5055b050950f` | Organize scripts by responsibility. | Keep moves, imports, subprocess paths, and tests atomic. |
| `6c153b1f5c2491b622540e0467d354532942c352` | `74ddc1cd6adf4b8b3565d4647895a04efcf547af` | Complete Level Studio rendering and playtesting. | Preserve the editor-to-runtime vertical slice. |
| `7ccca4955f2ae494081025083405ceec92cdd175` | `6d5e1ac513324bcb648543d1e589d5a0ed094da1` | Add standalone sound preview and trace comparison. | Preserve the sequencer, renderer, toolchain, and fidelity evidence together. |
| `696702e95e8f5871fe50ee14b982771ecd1c071c` | `ab75d93ec74ab156354d6ea45f6cb7973ddf3da0` | Match Level Studio to VDP presentation. | Preserve the focused visual-correctness fix and regressions. |
| `fc1d2bc33d4e7dc0e2e05cd9525e876fcfef7f6b` | `d0963008aa19c7b80e0acb778a93f50730a949db` | Modernize repository layout and the public release interface. | Combine the structural draft with the current project-owned manifest and audit policy so legacy review provenance is absent from the candidate tree. |

All replacements are nonempty. AuthorDate and CommitDate are monotonic in
parent order. Direct replays keep their original timestamps; combined cleanup
uses a timestamp inside the interval between the represented draft and the
current correction.

The remote-tracked baseline remains unchanged. Its historical release-policy
metadata, together with old local branches and tags, is deliberately outside
this rewrite. Any coordinated cleanup or ref removal is deferred to explicit
owner review; this branch neither rewrites published objects nor deletes local
recovery refs.
