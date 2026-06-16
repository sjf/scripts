### Project
- These are small scripts for my use only.
  - Prioritize simplicity. These scripts will be maintained by a human, so prioritize small scripts with fewer lines of code.
  - They do not have to run everywhere, only I will use them.
  - Do make params configurable unless aboslutely necessary. e.g. a service's port should be configurable, but the log file location does not.

### Code style
- Avoid unneccesary helper functions.
- These files will be read by a human, top to bottom. So follow the newspaper style of putting the most important functions (main loop etc) at the top of the file. Put helper functions at the bottom.

### Conventions
- logs should go in ~/.logs/<app-name>
