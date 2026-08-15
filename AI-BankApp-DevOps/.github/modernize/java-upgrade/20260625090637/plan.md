# Upgrade Plan: AI-BankApp-DevOps (20260625090637)

- **Generated**: 2026-06-25 09:06:37
- **HEAD Branch**: main
- **HEAD Commit ID**: N/A

## Available Tools

**JDKs**
- JDK 21: not available (baseline will be skipped)
- JDK 25.0.2: C:\Program Files\Java\jdk-25.0.2\bin (required by step 1, step 3, step 5)

**Build Tools**
- Maven Wrapper: 3.9.7 (.mvn/wrapper/maven-wrapper.properties)
- Maven 3.9.15: C:\bin\apache-maven-3.9.15-src\apache-maven-3.9.15\apache-maven\src\bin (available, wrapper preferred)

## Guidelines

> Note: You can add any specific guidelines or constraints for the upgrade process here if needed, bullet points are preferred.

## Options

- Working branch: appmod/java-upgrade-20260625090637
- Run tests before and after the upgrade: true

## Upgrade Goals

- Upgrade Java runtime from 21 to 25

## Technology Stack

| Technology/Dependency    | Current | Min Compatible | Why Incompatible |
| ------------------------ | ------- | -------------- | ---------------------------------------------- |
| Java                     | 21      | 25             | User requested target runtime upgrade          |
| Spring Boot              | 3.4.13  | 3.4.13         | No framework upgrade required for Java 25     |
| Maven Wrapper            | 3.9.7   | 3.9.0          | Compatible with Java 25                        |
| GitHub Actions setup-java| 21      | 25             | Workflow JDK must install target runtime       |
| Docker base image        | eclipse-temurin:21-jdk-alpine | 25-jdk-alpine | Container runtime must match Java target |

## Derived Upgrades

- Update runtime references from Java 21 to Java 25 in build, CI, and container configuration.
- No Spring Boot or major dependency version upgrade is required for this runtime-only change.

## Impact Analysis

### Dependency Changes

| File | Dependency | Current | Action | Target | Reason |
|------|-----------|---------|--------|--------|--------|
| pom.xml | java.version | 21 | upgrade | 25 | User requested runtime upgrade |

### Source Code Changes

| File | Location | Current | Required Change | Reason |
|------|----------|---------|----------------|--------|
| N/A | N/A | N/A | N/A | No Java source changes are required for this runtime upgrade |

### Configuration Changes

| File | Property/Setting | Current | Required Change | Reason |
|------|------------------|---------|----------------|--------|
| Dockerfile | base build image | eclipse-temurin:21-jdk-alpine | eclipse-temurin:25-jdk-alpine | Align build image with target runtime |
| Dockerfile | runtime image | eclipse-temurin:21-jre-alpine | eclipse-temurin:25-jre-alpine | Align runtime image with target JDK |
| .github/workflows/ci.yml | actions/setup-java java-version | '21' | '25' | CI must provision Java 25 |
| .github/workflows/build.yml | actions/setup-java java-version | '21' | '25' | Container build workflow must use Java 25 |
| README.md | Java version badge/link | Java-21 | Java-25 | Documentation should reflect the new target runtime |

### CI/CD Changes

| File | Location | Current | Required Change |
|------|----------|---------|----------------|
| .github/workflows/ci.yml | step names and setup block | Set up JDK 21 | Change to Set up JDK 25 |
| .github/workflows/build.yml | setup-java block | java-version: '21' | java-version: '25' |
| Dockerfile | build stage | eclipse-temurin:21-jdk-alpine | eclipse-temurin:25-jdk-alpine |
| Dockerfile | runtime stage | eclipse-temurin:21-jre-alpine | eclipse-temurin:25-jre-alpine |

### Risks & Warnings

- **Baseline skipped**: Java 21 is not installed on the local machine, so a true pre-upgrade baseline using the current runtime is not available. **Mitigation**: rely on current repository state and full compile/test verification under the target JDK.
- **Spring Boot 3.4.13 runtime compatibility**: Spring Boot 3.4.x may not have been validated against Java 25 by this project. **Mitigation**: run full build and test suite after the upgrade.
- **Docker/CI runtime drift**: any residual references to Java 21 outside the identified files may cause inconsistent build behavior. **Mitigation**: verify with grep and update all found targets during execution.

## Upgrade Steps

- Step 1: Setup Environment
  - Rationale: Ensure Java 25 is available locally and the Maven wrapper is ready before applying runtime changes.
  - Changes to Make: None to source files; validate JDK and wrapper availability.
  - Verification: `./mvnw -v` with JDK 25; expected `Apache Maven 3.9.7` and `openjdk version "25`.

- Step 2: Setup Baseline
  - Rationale: Validate the current project state before upgrading. Skipped because the base JDK (21) is not installed locally.
  - Changes to Make: None.
  - Verification: skipped.

- Step 3: Upgrade runtime configuration to Java 25
  - Rationale: Apply the runtime version change across Maven, Docker, GitHub Actions, and documentation in one pass.
  - Changes to Make: Update `pom.xml`, `Dockerfile`, `.github/workflows/ci.yml`, `.github/workflows/build.yml`, and `README.md` per Impact Analysis.
  - Verification: `./mvnw clean test-compile -q` using JDK 25.

- Step 4: CVE Validation & Fix
  - Rationale: Confirm the direct dependency graph is free of known Java dependency CVEs after the runtime upgrade.
  - Changes to Make: Run a direct dependency CVE scan and apply any patch upgrades required by the scan.
  - Verification: `./mvnw clean test-compile -q` plus CVE scan results.

- Step 5: Final Validation
  - Rationale: Confirm the upgraded runtime is fully supported and all tests pass.
  - Changes to Make: Resolve any compile-time or test failures introduced by the runtime move.
  - Verification: `./mvnw clean test -q` using JDK 25.
