# Decidim

Free Open-Source participatory democracy, citizen participation and open government for cities and organizations

This is the open-source repository for code, based on [Decidim](https://github.com/decidim/decidim).

## ChiCommons Chicago Decidim Implementation

This implementation is based on Decidim version 0.31.2

Additional gems deamons and delayed_job_active_record have been added for email service

Additional Decidim model gems are coded for but not currently implemented because of ops issues

Decidim comes up in development mode with emails handled by letter_opener_web

This installation is designed to run with docker compose. The repo code is mirrored in the container so that all code changes are mirrored directly in the container while it is running.

Setup procedure:
1. On Windows platforms stop insertion of line-ends: ```git config --global core.autocrlf input```
1. Clone this repo: ```git clone https://github.com/chicommons/Decidim_Chicago.git```
1. Change the working directory to the installed repo: ```cd Decidim_Chicago```

When implementing on Windows platforms we have encountered some problems with shakapacker where implementation gets stuck in a loop when the docker compose up command is issued. We have found that recompiling shakapacker with the following code remedies this problem:

```
docker compose exec decidim rm -rf public/decidim-packs node_modules
docker compose exec decidim npm install
docker compose exec decidim bundle exec rails shakapacker:compile
```


## Setting up the application

You will need to do some steps before having the app working properly once you have deployed it:

1. Create a System Admin user: `bin/rails decidim_system:create_admin`
1. Visit `<your app url>/system` and log in with your system admin credentials
1. Create a new organization. Check the locales you want to use for that organization, and select a default locale.
1. Set the correct default host for the organization, otherwise the app will not work properly. Note that you need to include any subdomain you might be using.
1. Fill the rest of the form and submit it.

You are good to go!
