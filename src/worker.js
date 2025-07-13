import htmlPage from '../public/index.html';


const repositories = {
    google: "https://dl.google.com/dl/android/maven2",
    central: "https://repo.maven.apache.org/maven2",
    jitpack: "https://jitpack.io",
};
export default {
    async fetch(request) {
        const url = new URL(request.url);

        // Extract the first part of the path
        const pathSegments = url.pathname.split('/').filter(Boolean); // Filter removes empty segments
        const repoKey = pathSegments[0]; // First segment of the path

        if (pathSegments.length === 0) {
            return new Response(htmlPage, {
                headers: { "content-type": "text/html; charset=utf-8" },
            });
        }

        // Check if the URL starts with a specific repository key
        if (repositories[repoKey]) {
            const response= await fetchFromRepository(repositories[repoKey], url.pathname.replace(`/${repoKey}`, ''), request);
            if(response.ok) return response
        }else{
            for (const repoUrl of Object.values(repositories)) {
                const response = await fetchFromRepository(repoUrl, url.pathname, request);
                if (response.ok) return response; // Return the response if successful
            }
        }

        return new Response("Dependency Not Found.", { status: 404 });
    },
};

async function fetchFromRepository(baseUrl, path, request) {
    const targetUrl = `${baseUrl}${path}`;

    if (!path || path === '/') return new Response("",{status: 404})
    return await fetch(targetUrl, {
        method: request.method,
        headers: request.headers,
        body: ['GET', 'HEAD'].includes(request.method) ? null : request.body,
    });
}
