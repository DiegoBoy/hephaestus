#!/usr/bin/env node
import { Client } from "@notionhq/client"
import { DatabasesQueryParameters, PagesCreateParameters } from "@notionhq/client/build/src/api-endpoints"
import { FSWatcher, access, readdir, stat, watch } from "fs"
import { exit } from "process"
import yargs from "yargs"
import { hideBin } from "yargs/helpers"

export class AutoRePort {
    private static isBuilder: boolean = false

    private databaseId: string
    private watchedPromises: Promise<void>[]
    private notion: Client
    private pageId: string
    private postedPorts: {[key: string]: boolean}
    private scansDir: string
    private watcher: FSWatcher
    
    constructor(scansDir: string, pageId: string, notionApiKey: string) {
        if (!AutoRePort.isBuilder) {
            throw new Error("AutoRePort requires async inititalization, call AutoRePort.getInstance() instead.")
        }

        this.watchedPromises = []
        this.notion = new Client({ auth: notionApiKey })
        this.pageId = pageId
        this.postedPorts = {}
        this.scansDir = scansDir
    }

    public static async getInstance(scansDir: string, pageId: string, notionApiKey: string) : Promise<AutoRePort> {
        // we can do this safely only because JS is single-threaded
        AutoRePort.isBuilder = true
        const instance = new AutoRePort(scansDir, pageId, notionApiKey)
        AutoRePort.isBuilder = false

        // check access to the Notion page
        await instance.assertAccessToPage()
        instance.databaseId = await instance.getPortsDatabaseId()
        
        // check access to the Notion database
        await instance.assertAccessToDatabase()

        return instance
    }

    public async report() {
        
        try {
            // check access to scans directory
            access(this.scansDir, async (e) => {
                // throw if directory cannot be accessed
                if (e) { throw e }

                // process each directory entry
                this.processScansDir()
            })
        } catch (error) {
            console.error(error)
        }
    }

    public watch() {
        this.watcher = watch(this.scansDir, (_, x) => this.processDirEntry(x))

        // if there's entries already, process them
        access(this.scansDir, (e) => {
            if (e) { 
                console.warn("Couldn't access the scans directory, make sure it exists and is readable.")
            } else {
                // process each directory entry
                this.processScansDir()
            }
        })
    }

    public async unwatch() {
        this.watcher?.close()
        await Promise.allSettled(this.watchedPromises)
    }
    
    private processScansDir() {
        readdir(this.scansDir, (e, contents) => {
            if (e) {
                // if NOENT, return
                if (e.code && e.code == "ENOENT") { return } 
                else { throw e }
            } else {
                contents.forEach(dirEntry => this.processDirEntry(dirEntry))
            }
        })
    }
    
    private processDirEntry(dirEntry: string) {
        stat(this.scansDir + "/" + dirEntry, (e, stats) => {
            if (e) {
                // if NOENT, return
                if (e.code && e.code == "ENOENT") { return } 
                else { throw e }
            } else if (stats && stats.isDirectory()) {
                // check if it matches tcp{port_number}
                const matches = dirEntry.match("(tcp|udp)(\\d+)")
                if (matches) {
                    const protocol = matches[1]
                    const portNumber = Number.parseInt(matches[2])                                
                    const appendPromise = this.appendToPortsDatabase(portNumber, protocol)
                    this.watchedPromises.push(appendPromise)
                }
            }
        })
    } 
    
    private async assertAccessToPage() {
        try {
            await this.notion.pages.retrieve({ page_id: this.pageId })
        } catch (error) {
            throw new Error(`"AutoRePort couldn't access the Notion page: ${this.pageId}\n\n${error.body}` )
        }
    }
    
    private async getPortsDatabaseId() : Promise<string> {
        try {
            // get database where we'll create the main page
            const children = await this.notion.blocks.children.list({block_id: this.pageId})
            return children.results.find(x =>  x.type.toString() == "child_database" ).id
        } catch (error) {
            console.error("Couldn't get 'Open ports' database ID.")
            console.error(error.body)
        }
    }
    
    private async assertAccessToDatabase() {
        try {
            await this.notion.databases.retrieve({ database_id: this.databaseId })
        } catch (error) {
            console.error("AutoRePort couldn't access the Notion database: " + this.databaseId)
            console.error(error.body)
            exit(1)
        }
    }
    
    private async appendToPortsDatabase(port: number, protocol: string) {
        //const titleColName = await getDbTitleColName()
        const portStr = port.toString()
        const dbQueryPayload : DatabasesQueryParameters = {
            database_id: this.databaseId,
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
                database_id: this.databaseId
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
            const portHash = `${this.databaseId}:${protocol}:${portStr}`
            if (!this.postedPorts[portHash]) {
                // check if database already contains page
                const queryResponse = await this.notion.databases.query(dbQueryPayload)
                if (queryResponse.results.length == 0) {
                    // create the page
                    await this.notion.pages.create(newPagePayload)
                }
            }
    
            // track port as posted
            this.postedPorts[portHash] = true
        } catch (error) {
            console.error(error.body)
        }
    }
}

interface AutoRePortArgs {
    outputDir: string,
    pageId: string,
    notionApiKey: string,
    watchMode: boolean,
    testMode: boolean
}

async function parseArgv() : Promise<AutoRePortArgs> {
    const args = yargs(hideBin(process.argv))
        .option("notionApiKey", {
            alias: "k",
            description: "Notion API key",
            type: "string",
            required: true
        })    
        .option("outputDir", {
            alias: "o",
            default: "./results",
            description: "AutoRecon's output directory",
            type: "string",
            required: false
        })
        .option("pageId", {
            alias: "i",
            description: "ID or URL of the Notion page shared with AutoRePort",
            type: "string",
            required: true
        })
        .option("watchMode", {
            alias: "w",
            default: false,
            description: "Watch mode loops looking for new AutoRecon's output - " +
                "it waits for the output dir if it doesn't exist yet",
            type: "boolean",
            required: false
        })
        .option("testMode", {
            alias: "t",
            default: false,
            description: "Tests access to Notion resources",
            type: "boolean",
            required: false
        })
        .help(false)
        .version(false)
        
    
    args.wrap(args.terminalWidth())
        
    // parse pageId if URL was provided
    const argv = args.coerce("pageId", (pageId) => {
        const regex = "https:\/\/www\.notion\.so\/(.+)\/(.+-)?([a-z0-9]{32})(.+)?"
        const matches = pageId.match(regex); 
        if (matches) {
            return matches[3]
        } else { 
            return pageId
        }
    }).argv
    
    return argv
}

async function main() {
    try {
        const argv = await parseArgv()
        console.log((argv))
        const autoRePort = await AutoRePort.getInstance(argv.outputDir + "/scans", argv.pageId, argv.notionApiKey)

        if (argv.testMode) {
            return
        } else if (argv.watchMode) {
            autoRePort.watch()

            process.on('SIGINT', async function() {
                await autoRePort.unwatch()    
            });
        } else {
            await autoRePort.report()
        }
    } catch (e) {
        console.error(e.message)
        exit(1)
    }
}

main()
