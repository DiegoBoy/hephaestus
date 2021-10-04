import { Client } from "@notionhq/client"
import { DatabasesQueryParameters, PagesCreateParameters } from "@notionhq/client/build/src/api-endpoints"
import { stat, readdir, access } from "fs"
import { exit } from "process"
import yargs from "yargs"
import { hideBin } from "yargs/helpers"

const argv = parseArgs()
const pageId = parsePageIdOrExit(argv.notionUrl)
const scansDir = argv.scansDir
const monitorMode = argv.monitorMode
const notion = new Client({ auth: process.env.NOTION_KEY })
var postedPorts = {}

function parseArgs() : any {
    //yargs(hideBin(process.argv))
    return yargs(hideBin(process.argv))
        .option("notionUrl", {
            alias: "u",
            description: "URL of the Notion page shared with AutoRePort",
            type: "string",
            required: true
        })
        .option("scansDir", {
            alias: "d",
            default: "./results/scans",
            description: "AutoRecon's 'scans' directory",
            type: "string",
            required: false
        })
        .option("monitorMode", {
            alias: "m",
            default: false,
            description: "Monitor mode loops looking for new AutoRecon's output." +
                "It waits for the 'scans' dir if it doesn't exist yet.",
            type: "boolean",
            required: false
        })
        .help().alias("help", "h")
        .argv
}

function parsePageIdOrExit(notionUrl: string) : string {
    // get pageId from Notion url using regex
    const matches = notionUrl.match("https://www\.notion\.so/(.+)/(.+-)?([a-z0-9]{32})(.+)?"); 
    if (!matches) { 
        console.error("Notion URL didn't match the expected regex.")
        exit(1) 
    }

    return matches[3]
}

async function assertAccessToPage(pageId: string) {
    try {
        await notion.pages.retrieve({ page_id: pageId })
    } catch (error) {
        console.error("AutoRePort couldn't access the Notion page: " + pageId)
        console.error(error.body)
        exit(1)
    }
}

async function getPortsDatabaseId(pageId: string) : Promise<string> {
    try {
        // get database where we'll create the main page
        const children = await notion.blocks.children.list({block_id: pageId})
        return children.results.find(x =>  x.type.toString() == "child_database" ).id
    } catch (error) {
        console.error("Couldn't get 'Open ports' database ID.")
        console.error(error.body)
    }
}

async function assertAccessToDatabase(databaseId: string) {
    try {
        await notion.databases.retrieve({ database_id: databaseId })
    } catch (error) {
        console.error("AutoRePort couldn't access the Notion database: " + databaseId)
        console.error(error.body)
        exit(1)
    }
}

async function appendToPortsDatabase(databaseId: string, port: number, protocol: string) {
    //const titleColName = await getDbTitleColName()
    const portStr = port.toString()
    const dbQueryPayload : DatabasesQueryParameters = {
        database_id: databaseId,
        filter: {
          and: [
            {
              property: "Port",
              text: {
                equals: portStr,
              },
            },
            {
              property: "Protocol",
              select: {
                equals: protocol,
              },
            },
          ],
        }
    }
    const newPagePayload : PagesCreateParameters = {
        parent: {
            database_id: databaseId
        },
        properties: {
			Port: {
				type: "title",
                title: [{
						"type": "text",
						"text": {
							"content": portStr,
						}
					}
				]
			},
            Protocol: {
                type: "select",
                select: {
                    "id": undefined,
                    "name": protocol,
                    "color": undefined
                }
            },
            Status: {
                type: "select",
                select: {
                    "id": undefined,
                    "name": "TODO",
                    "color": undefined
                }
            }
		} 
    }

    try {
        // check if we've seen the port before
        const portHash = protocol + portStr
        if (!postedPorts[portHash]) {
            // check if database already contains page
            const queryResponse = await notion.databases.query(dbQueryPayload)
            if (queryResponse.results.length == 0) {
                // create the page
                await notion.pages.create(newPagePayload)
            }
        }

        // track port as posted
        postedPorts[portHash] = true
    } catch (error) {
        console.error(error.body)
    }
}

async function postOpenPortsTCP(databaseId: string) {
    try {
        // check access to scans directory
        access(scansDir, async (e) => {
            if (e) { throw e }
            // get directory entries
            readdir(scansDir, (e, contents) => {
                if (e) { throw e }
                contents.forEach(x => {
                    // get stats for entry
                    stat(scansDir + "/" + x, (e, stats) => {
                        if (e) { throw e }
                        
                        // check if entry is a dir
                        if (stats && stats.isDirectory()) {
                            // check if it matches tcp{port_number}
                            const matches = x.match("(tcp|udp)(\\d+)")
                            if (matches) {
                                const protocol = matches[1]
                                const portNumber = Number.parseInt(matches[2])                                
                                appendToPortsDatabase(databaseId, portNumber, protocol)
                            }
                        }
                    })  
                })
            })
        })
    } catch (error) {
        console.error(error)
    }
}

async function main() {
    assertAccessToPage(pageId)

    const databaseId = await getPortsDatabaseId(pageId)
    assertAccessToDatabase(databaseId)

    // if monitor mode, execute every 10s
    if (monitorMode) {
        setInterval(async () => { 
            await postOpenPortsTCP(databaseId)
        }, 2000)
    } else {
        await postOpenPortsTCP(databaseId)
    }
    
}

main()
