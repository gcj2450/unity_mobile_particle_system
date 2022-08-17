# Unity GPU Mobile Particle System
Highly efficient/compatible Unity Particle System
- Target Level 2.0 (Works on all platforms supported by Unity)
- Every calculation (pos, collision, etc) is done by the GPU (CPU only generate the meshes)
- A single draw call per frame
- No dynamic allocations
- Stateless

#### How to use:
- Clone project
- In Unity 2018.2: `Assets > Import Package > Custom Package...`
- Select `ParticleMobile.unitypackage`
- In `Project` tab open `ParticleMobile` folder and drag `ParticleEmitter` prefab to your Scene
![MobileParticle](https://user-images.githubusercontent.com/11438971/185072502-e810a3d6-2781-461d-9585-255e22d55ea5.png)
