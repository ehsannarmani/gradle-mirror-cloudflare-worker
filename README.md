## Gradle Mirror By Cloudflare Workers

#### This mirror developed to download gradle dependencies without network interference and sanctions

### Usage:

Simply add the mirror url as a maven repository in the `settings.gradle` file and re-sync project:

```kotlin
pluginManagement {
    repositories {
        maven("https://en-mirror.ir")
    }
}
dependencyResolutionManagement {
    ...
    repositories {
        maven("https://en-mirror.ir")
    }
}
```
> [!NOTE]
> Clone of mirror is launched at `en-mirror.ir` and ready to use. this mirror contains `google`,`central` and `jitpack` mavens.
### Repository Filtering
By default, all repositories are mirrored. To mirror only a specific repository, include its key in the mirror URL, like this:
```kotlin
maven("https://en-mirror.ir/jitpack")
```

### Worker Setup:
- <strong>Manual Setup</strong>:
  - Login to cloudflare
  - Click on workers & pages tab
  - Create new worker with optional name and click on deploy
  - In the new tab, click on edit code
  - Copy & Paste worker.js codes into opened tab and click on deploy button
- <strong>CLI Setup</strong>:
  - Ensure you have Node.js installed on your system, then install the Wrangler CLI: 
    - `npm install -g wrangler`
  - Login to your cloudflare account using: `wrangler login`
  - Update configuration in wrangler.toml:
    - Set `compatibility_date` field to current date
    - Set id field in [account] group to your cloudflare worker account id, you can find it in:
      - Simply in cloudflare dashboard, click on Workers & Pages tab and on the right side you can find the account id
  - Deploy the worker using: `wrangler deploy`
#### Now, your worker is ready to use and the mirror url is your worker url in this pattern: `https://[worker-name].[cloudflare-username].workers.dev/`

### Custom Domain:
- Set up your domain in Cloudflare, configure the DNS servers on the domain, and wait until the domain becomes active
- After your domain becomes active, click on websites tab and select your domain
- Click on DNS tab and add new `CNAME` record, set content to your worker domain: `[worker-name].[cloudflare-username].workers.dev`
- Keep proxied checked
- Click on Worker Routes tab and add route
- If you want to mirror your root domain, enter the route like this: `https://your-domain.com/*`
- Select the created worker and click on save.
#### Now your custom domain should be connected to worker, and you can use your own mirror!
