// RealtimeKit, which PipeWire and WirePlumber ask for realtime scheduling
// (their mod.rt). Only pulseaudio depends on it, and Omarchy runs
// pipewire-pulse, so nothing pulls it in on x86_64: without it every audio
// thread runs at normal priority (journal: "RTKit error: ... ServiceUnknown").
// Omarchy lists it for aarch64 only. PipeWire picks it up at its next start.
import { omarchy, program } from "loadout";

export const rtkit = program("rtkit", { install: [omarchy] });
