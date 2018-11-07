# Unity GPU Mobile Particle System

- Target Level 2.0 (Works on all platforms supported by Unity)
- Every calculation (pos, collision, etc) is done by the GPU (CPU only generate the meshes)
- A single draw call per frame
- No dynamic allocations

#### How to use:
- Clone project
- In Unity 2018.2: `Assets > Import Package > Custom Package...`
- Select `ParticleMobile.unitypackage`
- In `Project` tab open `ParticleMobile` and drag `ParticleEmitter` prefab to your Scene
