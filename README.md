# Advanced Windows Network Toolkit

**Architect & Lead Developer:** Lucilyn Tangian  
**Version:** 1.1.0  
**Release Date:** September 2026  

## System Architecture
This toolkit is a zero-dependency, native Windows Command Prompt (CMD) application designed for L3/L7 network triage. It requires no external scripting engines, executable wrappers, or installation, ensuring immediate execution on locked-down enterprise endpoints.

### Key Engineering Decisions
* **Automated Stateful Logging:** Dynamically generates timestamped output directories (`%USERPROFILE%\Documents\NetworkToolkitLogs`) to ensure audit trails for incident post-mortems without file overwrite collisions.
* **Strict Privilege Guardrails:** Implements native `fltmc` elevation checks to prevent unprivileged execution of state-changing commands (e.g., DNS flushing, TCP/IP stack resets).
* **Drag-and-Drop Resolution:** Includes custom logic to parse file paths or raw string inputs, dynamically sanitizing URLs and bracketed IPv6 targets for instant diagnostic execution.
* **Isolated "Read-Only" vs "State-Changing" Execution Blocks:** Protects end-users by segregating non-destructive data collection from high-impact connectivity changes, enforcing explicit approval prompts before executing the latter.

## Usage Instructions
1. Right-click `advanced_network_toolkit_v1.1.cmd` and select **Run as Administrator**.
2. Alternatively, drag and drop a text file containing an IP or Domain directly onto the script icon to trigger an immediate targeted diagnostic suite.

## Security & Integrity
To verify the integrity of this script and ensure no unauthorized command injections have been made, check the file against its official cryptographic hash (refer to release notes).
