# Testrunner

This is the repository for the scripts we use to execute our [E2E-tests](https://github.com/mint-o-badges/oeb-test) automatically and post the results on Mattermost. For this to work, you need a file called `secret` with the following contents:
- `nextcloudCredentials="<username:password>"`
- `sharingKey="<sharing key for nextcloud>"`
- `mattermostUrl="<url including the hook secret>"`
