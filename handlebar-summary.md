# Handlebar: A Platform for Empirical Research on Mobile UI Interactions

## Overview

Handlebar is a research platform that enables empirical studies of how people interact with Android applications. It pairs a Flutter mobile app with CREPE (Contextual Recognition and Extraction of Patterns from UI Elements), an Android accessibility service that captures structured representations of on-screen UI elements in real time. Together, they allow researchers to define what data to collect from participant devices, collect it passively, and analyze interaction patterns across apps and users.

## Motivation

Studying how people use mobile apps in naturalistic settings is difficult. Existing approaches rely on self-report, screen recordings requiring manual coding, or instrumentation of individual apps. Handlebar addresses this by using Android's accessibility APIs to programmatically observe UI state across *any* app without modifying it. Researchers define data collection configurations visually, and participants contribute data passively once enrolled.

## Architecture

The system has three components:

- **Handlebar App** — A Flutter application serving both researchers (study design, data review) and participants (enrollment, passive data collection).
- **CREPE Plugin** — An Android accessibility service plugin that captures UI element trees, runs graph-based queries to match target elements, and monitors for matches continuously in the background.
- **Backend API** — A server that manages research groups, memberships, collector configurations, and collected event data.

## Key Features

### For Researchers

- **Video-based collector definition**: Upload a screen recording of a target app. Scrub through the recording while viewing synchronized UI snapshots overlaid on the video. Tap UI elements to select them and define data fields to monitor.
- **Graph query generation**: When a researcher selects a UI element, the system generates a structural query over the accessibility tree that can identify that element (or similar elements) in future snapshots.
- **Research group management**: Create groups, invite participants, assign roles, configure collectors, and review collected data.
- **Intersection-based analysis**: Tap on the video overlay to identify all UI elements at that position, sorted by z-index, enabling precise element selection even in complex UIs.

### For Participants

- **Passive data collection**: Once enrolled and with the accessibility service enabled, CREPE monitors the device in the background and logs matches against configured collectors.
- **Study consent and enrollment**: Join research groups via invite codes, review study terms, and manage data retention preferences.

### Recording and Replay

- **UI snapshot recording**: Captures periodic snapshots of the full accessibility tree alongside screen video. Snapshots are saved as compressed archives with metadata (device dimensions, timestamps).
- **Timeline replay**: A custom video player with synchronized snapshot overlay, frame-by-frame navigation, and visual markers showing snapshot positions on the scrubber.
- **Coordinate mapping**: Two-stage transformation maps bounding boxes from original device coordinates through video recording coordinates to the replay container, accounting for aspect ratio differences and letterboxing at each stage.

## Data Model

A **research group** contains members with researcher or participant roles. Researchers create **collectors**, each targeting a specific app and containing one or more **data fields** — patterns defined over the accessibility tree. When CREPE detects a match on a participant's device, it produces a **CrepeEvent** with the matched content, timestamp, and membership context.

## Implementation Notes

- CREPE uses Android's `AccessibilityService` API to read UI element properties (text, bounds, clickability, content descriptions, visibility) without requiring root access or app modification.
- Snapshot overlays filter for "interesting" nodes (clickable, editable, or text-bearing) to reduce visual clutter from container elements.
- The plugin filters out system UI, launcher, and Handlebar's own elements from captures.
- Snapshot timing is aligned to video playback by recording the video start timestamp in metadata and computing relative offsets.
