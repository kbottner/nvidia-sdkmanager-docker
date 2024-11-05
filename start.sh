#!/bin/bash

# Launch NVIDIA SDK Manager (it will exit and run in background)
/usr/bin/sdkmanager

# Let's keep a bash shell running because it's useful.
exec /bin/bash
