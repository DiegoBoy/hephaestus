import { Client } from "@notionhq/client"

const notion = new Client({ auth: process.env.NOTION_KEY })
const databaseId = process.env.NOTION_DATABASE_ID

async function getDatabasePorts() {
  try {
    //const response = await notion.pages.retrieve({ page_id: databaseId })
    //const response = await notion.blocks.children.list({block_id: databaseId})
    const response = await notion.search({filter: {property: "object", value: "database"}})
    console.log(JSON.stringify(response))
    console.log(response)
  } catch (error) {
    console.error(error.body)
  }
}

getDatabasePorts()