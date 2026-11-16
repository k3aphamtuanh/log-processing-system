# Kubernetes Core — Hands-on Lab Evidence & Incident Reasoning

**Project:** Log Processing System  
**Environment:** AWS EC2, Kubernetes single-node lab  
**Learning status:** 15/15 Core lessons completed  
**Evidence status:** Lessons 1–13 hands-on; Lessons 14–15 simulated incident exercises

## 1. Purpose and Evidence Scope

This document records Kubernetes learning through practical experiments, failure investigation, recovery, and verification.

Evidence is classified into two categories:

- **Hands-on lab:** Kubernetes actions performed in an AWS environment, reconstructed from historical study notes. Original command outputs are not fully preserved.
- **Simulated incident:** Scenario-based troubleshooting exercises conducted in conversation. These are not AWS execution logs or production incidents.

Completion of Kubernetes Core does not imply production-level Kubernetes expertise or CKA certification.

## 2. Lab Environment

| Component | Historical configuration |
|---|---|
| Cloud | AWS EC2, Tokyo |
| Instance | EC2-02-K8s-Lab |
| Operating system | Ubuntu 24.04 |
| Kubernetes | v1.36.4 |
| Cluster | kubeadm, single control-plane node |
| Container runtime | containerd 2.2.1 |
| Networking | Flannel |
| Application image | `localhost/log-processing-system:v1` |
| Deployment | `web-deploy`, 3 replicas |
| Service | `web-service` |
| Application endpoints | `/health`, `/report` |

The application image was historically built using Podman, exported as a tar archive, and imported into containerd's `k8s.io` image store.

The Dockerfile and Kubernetes manifests used during these labs are not currently tracked in this GitHub repository. The current GitHub application code may differ from the code packaged in the historical Kubernetes image.

## 3. System Architecture

**Workload control**

`Deployment → ReplicaSet → Pod → Container → Application process`

**Application traffic**

`Client → Service:80 → PodIP:8000 → Application`

**Health probes**

`kubelet → PodIP:8000/health`

**Control operations**

`kubectl → API Server → Kubernetes resources`

The Service path, probe path, and control path were investigated independently.

## 4. Hands-on Lab Results — Lessons 1–13

| Lesson | Experiment and observed result |
|---|---|
| 1 | Stopped kubelet; Node became NotReady while containerd continued running |
| 2 | Deleted a Deployment-managed Pod; ReplicaSet restored the desired replica count |
| 3 | Tested stable Service access despite changes to Pod IP addresses |
| 4 | Changed Pod labels; observed Service endpoint selection and ReplicaSet reconciliation |
| 5 | Tested namespaces and resource scoping |
| 6 | Injected environment variables from ConfigMap and Secret; investigated restart behavior |
| 7 | Tested readiness failure and liveness-triggered restarts |
| 8 | Investigated image, process, probe, and Service configuration failures |
| 9 | Migrated a Deployment from nginx to the Python application image; corrected outdated probes |
| 10 | Traced kubelet, CRI, and containerd relationships; compared runtime container and image IDs |
| 11 | Reproduced scheduling failure and OOMKilled behavior using resource constraints |
| 12 | Investigated a failed rollout and restored the previous working Pod template |
| 13 | Verified Deployment configuration and corrected a Service targetPort mismatch |

These results are historical lab summaries. Exact original outputs are unavailable for some lessons.

## 5. Selected Failure Investigations

### Case A — Application Image Migration

The existing Deployment previously ran nginx on port 80. It was updated to use the Python application image listening on port 8000.

Command used:

`kubectl set image deployment/web-deploy nginx=localhost/log-processing-system:v1`

The container retained the legacy name `nginx`; this was a container identifier, not the actual application process.

**Failure:** Existing readiness and liveness probes still targeted the old nginx port and path.

**Correction:** Updated the probes to use port `8000` and path `/health`.

**Result:** The new application Pods reached healthy running states.

### Case B — CPU Scheduling Failure

A Deployment resource request was changed to:

`cpu=1500m,memory=128Mi`

**Observed evidence:** New Pods remained Pending with `FailedScheduling: Insufficient cpu`.

**Recovery:** Reduced CPU requests to `300m` per Pod.

**Result:** Three application replicas became available again.

**Conclusion:** Scheduling failure occurs before image retrieval and container startup.

### Case C — Memory Limit / OOMKilled

A separate `resource-limit-lab` Deployment was configured with a `10Mi` memory limit.

**Observed evidence:**

- Termination reason: `OOMKilled`
- Exit code: `137`
- Restart count observed: `6`
- BackOff events

The memory limit was raised to `128Mi`.

**Result:** Replacement Pod reached `1/1 Running` with zero restarts.

The temporary lab Deployment was subsequently removed.

### Case D — Failed Rollout and Rollback

A test rollout used the image reference:

`localhost/log-processing-system:v999`

**Observed failure:** The new surge Pod could not be scheduled because of insufficient CPU capacity.

The rollout exceeded its progress deadline.

**Recovery:** Executed `kubectl rollout undo deployment/web-deploy`.

**Result:** The previous working Pod template was restored.

**Important finding:** The observed failure occurred before image pulling. Therefore, this experiment did not establish an image-pull failure.

Rollback also creates a new Deployment revision rather than decreasing the revision number.

### Case E — Service Port Mismatch

The Python application listened on port `8000`, but the Service retained its previous nginx configuration:

`Service:80 → targetPort:80`

The intended correction was applied through editing `web-service`:

`Service:80 → targetPort:8000`

**Evidence limitation:** The historical conversation contains the configuration change but not a final direct curl verification after the edit. Successful end-to-end traffic after this change is therefore not claimed as independently measured evidence.

## 6. Simulated Incident Exercises — Lessons 14–15

These exercises evaluated diagnostic reasoning and recovery decisions. All incident outputs in this section were simulated.

### Lesson 14 — Intermittent Connectivity

**Scenario:** Service requests intermittently returned HTTP 200 or timed out.

Direct tests showed two responding Pods and one intermittently unreachable Pod.

**Investigation approach:**

- Compare Service-level and Pod-level requests.
- Preserve evidence before intervention.
- Keep networking, resource, and application hypotheses open.
- Propose replacing only the affected stateless Pod, subject to permission.
- Verify replacement behavior before declaring recovery.

The exercise demonstrated fault localization without prematurely assigning a root cause.

### Lesson 15 — Multiple Pod Failure Modes

**Scenario:**

| Pod | Simulated response |
|---|---|
| A | `/report` HTTP 200 |
| B | `/report` HTTP 500 |
| C | `/health` and `/report` timeout |

**Simulated recovery:**

1. Replace Pod C and verify the replacement repeatedly.
2. Replace Pod B and verify the replacement repeatedly.
3. Keep the healthy Pod A available.
4. Verify application responses through the Service.

Simulated replacement Pods and Service requests returned HTTP 200 during verification.

**Operational principle:** Preserve evidence, restore service with the smallest appropriate intervention, and perform deeper root-cause analysis afterward.

When the suspected failure falls outside the operator's ownership, escalate with evidence rather than changing another team's backend or image without authorization.

## 7. Engineering Lessons

- A running Pod does not guarantee every application endpoint works.
- Readiness and liveness answer different operational questions.
- A Service port and a backend targetPort are independent configuration values.
- A resource request influences scheduling; a memory limit can cause OOM termination.
- Rollout failure must be investigated at the first failing stage.
- Successful rollback supports a change-related hypothesis but does not prove which underlying component caused the failure.
- Recovery and root-cause analysis are separate activities.
- Compare healthy and unhealthy replicas before expanding an investigation.
- Keep the blast radius of recovery actions as small as possible.

## 8. Limitations and Follow-up Evidence

This documentation does not claim that:

- All 15 lessons were executed against a live AWS cluster.
- Historical raw logs, screenshots, or YAML manifests are stored in the repository.
- The current GitHub code is identical to the historical Kubernetes image.
- The single-node lab represents a production-grade Kubernetes deployment.

When the environment is available, useful follow-up evidence includes the current Deployment and Service manifests, Pod status, and real HTTP verification results.

These should be recorded separately, with their actual execution dates.

## 9. Source and Project

- [Project repository](https://github.com/k3aphamtuanh/log-processing-system)
- [Kubernetes Core learning evidence — Notion](https://app.notion.com/p/41a945b65ed6816e8547d569efb80656)

**Kubernetes Core: 15/15 completed. Hands-on and simulation evidence remain explicitly distinguished.**
