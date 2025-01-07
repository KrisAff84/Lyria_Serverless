const apiEndpoint = "https://dmhtn2p9csmfo.cloudfront.net/prod/index"

async function fetchData() {
    const response = await fetch(apiEndpoint);
    if (!response.ok) {
        console.error("Failed to fetch data:", response);
        return;
    }
    return response.json();
}

window.fetchData = fetchData;