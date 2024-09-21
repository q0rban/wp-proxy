const fs = require('fs/promises');
const handlebars = require("handlebars");
const path = require('path');
const yaml = require('js-yaml');

const filepath = process.env.WP_PROXY_MAP_FILE;
// The path to where WP Proxy is installed.
const wpproxydir = process.env.WP_PROXY_DIR;

async function checkConfig() {
    if (!filepath) {
        throw new Error('You must declare the path to the yaml map file in a WP_PROXY_MAP_FILE environment variable.');
    }
    try {
        await fs.access(filepath, fs.constants.R_OK);
    } catch (error) {
        throw new Error(`The yaml map file '${filepath}' does not exist or is not readable.`);
    }
    if (!wpproxydir) {
        throw new Error('You must declare the directory where WP Proxy is installed in a WP_PROXY_DIR environment variable.');
    }
    try {
        await fs.access(path.join(wpproxydir, 'conf.d'), fs.constants.R_OK);
    } catch (error) {
        throw new Error(`The directory '${wpproxydir}/conf.d' does not exist or is not readable.`);
    }
}

async function getMap() {
    const rawYaml = await fs.readFile(filepath, 'utf8');
    const map = yaml.load(rawYaml);
    if (!map) {
        throw new Error(`The yaml map file '${filepath}' is empty`);
    }
    return map;
}

function parseMapRow(host, mapItem, defaultBackendUri){
    // Strip off trailing slashes on the backend URI.
    const backend_uri = (mapItem.backend_uri || defaultBackendUri).replace(/\/+$/, '');
    return {
        source_host: mapItem.host || host,
        backend_uri,
        source_scheme: mapItem.scheme || 'https',
        proxy_scheme: mapItem.proxy_scheme || 'https',
        proxy_host: mapItem.proxy_host || mapItem,
    };
}

async function run() {
    await checkConfig();
    const map = await getMap();
    const templateString = await fs.readFile(path.join(wpproxydir, 'vhost.tpl.conf'), 'utf8');
    const template = handlebars.compile(templateString);
    const defaultBackendUri = map.backend_uri;
    const vhosts = [];
    const substitutions = [];

    for (let [host, mapItem] of Object.entries(map.sites)) {
        const vhost = parseMapRow(host, mapItem, defaultBackendUri);
        vhosts.push(vhost);
        const substitution = `s|${vhost.source_scheme}://${vhost.source_host}|${vhost.proxy_scheme}://${vhost.proxy_host}|ni`;
        substitutions.push(substitution);
    }

    vhosts.forEach((vhost) => {
        const context = {
            ...vhost,
            substitutions,
        };
        const output = template(context);
        fs.writeFile(path.join(wpproxydir, 'conf.d', `${vhost.source_host}.vhost`), output);
        console.log(`wp-proxy: Created vhost for ${vhost.source_scheme}://${vhost.source_host} at ${vhost.proxy_scheme}://${vhost.proxy_host} running on backend server ${vhost.backend_uri}.`);
    })
}

run()
    .then(() => console.log('WP Proxy config generation completed successfully.'))
    .catch((error) => {
        console.error(error.message);
        process.exit(1);
    });
