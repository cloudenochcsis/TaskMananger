# Security Update: Gunicorn 23.0.0

## Overview

This document records an important security update to the TaskManager application. We have upgraded Gunicorn from version 21.2.0 to version 23.0.0 to address a critical security vulnerability.

## Vulnerability Details

**CVE-2023-45133** (High Severity)
- **Affected Versions**: Gunicorn < 23.0.0
- **Fixed Version**: Gunicorn 23.0.0 or later
- **Description**: Versions of Gunicorn prior to 23.0.0 are vulnerable to HTTP Request Smuggling due to improper validation of the Transfer-Encoding header. This could potentially allow attackers to bypass security controls and gain unauthorized access to protected resources.

## Changes Made

The following changes were made to address this vulnerability:

1. Updated Gunicorn from version 21.2.0 to 23.0.0 in `TaskManager/requirements.txt`
2. Updated the Dockerfile to explicitly install Gunicorn 23.0.0
3. Updated deployment documentation to reflect the new version requirement
4. Created this security update document to record the change

## Verification

To verify that your installation is using the secure version of Gunicorn:

1. Check the installed version:
   ```bash
   pip show gunicorn
   ```

2. Ensure that the version is 23.0.0 or higher

## References

- [CVE-2023-45133](https://nvd.nist.gov/vuln/detail/CVE-2023-45133)
- [Gunicorn Release Notes](https://docs.gunicorn.org/en/stable/news.html)
- [GitHub Security Advisory](https://github.com/advisories/GHSA-45x7-px36-x8w8)
