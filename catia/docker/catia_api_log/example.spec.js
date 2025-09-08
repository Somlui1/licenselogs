import clipboardy from 'clipboardy';


function removePseudoHeaders(headers) {
  const cleanHeaders = {};
  for (const key in headers) {
    if (!key.startsWith(':')) {
      cleanHeaders[key] = headers[key];
    }
  }
  return cleanHeaders;
}
const { MongoClient } = require('mongodb');
async function saveToMongo(result,db,tb) {
  // MongoDB connection URI (เปลี่ยนตามของคุณ)
  const uri = 'mongodb://admin:it%40apico4U@10.10.10.181:27017/?authSource=admin';
  // สร้าง client
  const client = new MongoClient(uri);
  try {
    await client.connect();
    const database = client.db(db); // ชื่อฐานข้อมูล
    const collection = database.collection(tb); // ชื่อ collection
    // สมมติ result เป็น object หรือ array
    // ถ้า result เป็น array ให้ใช้ insertMany
    // ถ้า result เป็น object ให้ใช้ insertOne
    if (Array.isArray(result)) {
      const insertResult = await collection.insertMany(result);
      console.log(`${insertResult.insertedCount} documents inserted`);
    } else {
      const insertResult = await collection.insertOne(result);
      console.log(`Document inserted with _id: ${insertResult.insertedId}`);
    }
  } catch (err) {
    console.error('Failed to insert document(s):', err);
  } finally {
    await client.close();
  }
}
// ใช้งาน
import { test, expect } from '@playwright/test';
const path = require('path');
const process = require('process');
process.chdir(__dirname);

const util = require('util');

test('AA capture getLogs API call', async ({ page }) => {
  // ✅ สร้าง Promise สำหรับรอ request ที่ action = "getLogs"

  const username = 'aa.dsls@aapico.com'
  const password ='A@pico@2025'
  const licenseFilePath = 'C:\\Users\\wajeepradit.p\\OneDrive - AAPICO Hitech PCL\\project\\licenselogs\\catia\\docker\\ER1NQ-P0GYZ-981M8-WQVEP-D80QL_0000_1.LIC';
  
  const waitForGetLogsRequest = new Promise((resolve, reject) => {
    page.on('request', async (request) => {
      if (
        request.url().includes('/dslsws/api/service') &&
        request.method() === 'POST'
      ) {
        const bodyText = await request.postData();
        try {
           const json = JSON.parse(bodyText || '{}');
        if (json.action === 'getLogs') {
          const headers = await request.allHeaders(); // ✅ await ก่อน
          resolve({
            url: request.url(),
            headers,
            body: json,
            });
          }
        } catch (err) {
          reject(err);
        }
      }
    });
  });
  // ✅ เริ่มจาก login & action
  await page.goto('https://eu1.iam.3dexperience.3ds.com/cas/login?service=https%3A%2F%2Fr1132103523401-ap2-licensing-3.3dexperience.3ds.com%2Fdslsws%2F');
  await page.getByRole('button', { name: 'Accept All' }).click();
  await page.getByRole('textbox', { name: 'Email or username' }).click();
  await page.getByRole('textbox', { name: 'Email or username' }).fill(username);
  await page.getByRole('button', { name: 'Continue' }).click();
  await page.getByRole('textbox', { name: 'Password ' }).fill(password);
  await page.getByRole('textbox', { name: 'Password ' }).click();
  await page.getByText('Log inBack').click();
  await page.getByRole('button', { name: 'Log in' }).click();
  await page.waitForLoadState('networkidle');
  await page.getByRole('textbox').click();
  await page.getByRole('textbox').fill(password);
  await page.getByRole('button', { name: 'Choose file...' }).click();
  await page.locator('input[type="file"]').setInputFiles(licenseFilePath);
  await page.getByRole('button', { name: 'Connect' }).click();
  await page.getByRole('link', { name: '  Server Logs' }).click();
  await page.getByRole('textbox', { name: 'Start Date' }).click();
  await page.getByRole('button', { name: 'Move backward to switch to' }).dblclick();
  // ✅ รอจนกว่าจะเจอ request ที่ต้องการ

  let matchedRequest = await waitForGetLogsRequest;
  let result;
  matchedRequest.headers = removePseudoHeaders(matchedRequest.headers); // ✅ ลบ pseudo headers
  matchedRequest.body.parameters.fromDate = 0;
  try {
  expect(matchedRequest.body.action).toBe('getLogs');
  // เปลี่ยนค่าที่ต้องการใน matchedRequest.body
matchedRequest.body.parameters.numberOfRowsToReturn = 999999; // ลบเพื่อไม่จำกัดจำนวนแถว
  // ส่ง body ที่แก้ไขไปเลย
  const fetch = require('node-fetch');
  const response = await fetch(matchedRequest.url, {
    method: 'POST',
    headers: matchedRequest.headers,
    body: JSON.stringify(matchedRequest.body)  // <-- ใช้ matchedRequest.body แทน body
  });
  if (!response.ok) {
    console.error(`HTTP Error: ${response.status}`);
    console.log('Response Status:', response.status);
    console.log('Response Status Text:', response.statusText);
    return;
  }
  result = await response.json();
 console.log('✅ Matched getLogs request:');
} catch (error) {
  console.error('Error fetching logs:', error); 
}
  // await saveToMongo(result,'logs','AA');
  // console.log(util.inspect(result, {showHidden: false, depth: null, maxArrayLength: null}));;
  await clipboardy.write(JSON.stringify(result, null, 2));
  console.log('Done to set massage to Clipboard');  
});

test('AHA capture getLogs API call', async ({ page }) => {
  // ✅ สร้าง Promise สำหรับรอ request ที่ action = "getLogs"
  const username = 'aha.dsls@aapico.com'
  const password ='A@pico@2025'
  const licenseFilePath  = "C:\\Users\\wajeepradit.p\\OneDrive - AAPICO Hitech PCL\\project\\licenselogs\\catia\\docker\\EL57E-SAZKY-SL79X-3MBAC-UJPWV_0000_1.LIC";
  const waitForGetLogsRequest = new Promise((resolve, reject) => {
    page.on('request', async (request) => {
      if (
        request.url().includes('/dslsws/api/service') &&
        request.method() === 'POST'
      ) {
        const bodyText = await request.postData();
        try {
           const json = JSON.parse(bodyText || '{}');
        if (json.action === 'getLogs') {
          const headers = await request.allHeaders(); // ✅ await ก่อน
          resolve({
            url: request.url(),
            headers,
            body: json,
            });
          }
        } catch (err) {
          reject(err);
        }
      }
    });
  });
  // ✅ เริ่มจาก login & action
  await page.goto('https://r1132103523417-ap2-licensing-3.3dexperience.3ds.com');
  await page.getByRole('button', { name: 'Accept All' }).click();
  await page.getByRole('textbox', { name: 'Email or username' }).click();
  await page.getByRole('textbox', { name: 'Email or username' }).fill(username);
  await page.getByRole('button', { name: 'Continue' }).click();
  await page.getByRole('textbox', { name: 'Password ' }).fill(password);
  await page.getByRole('textbox', { name: 'Password ' }).click();
  await page.getByText('Log inBack').click();
  await page.getByRole('button', { name: 'Log in' }).click();
  await page.waitForLoadState('networkidle');
  await page.getByRole('textbox').click();
  await page.getByRole('textbox').fill(password);
  await page.getByRole('button', { name: 'Choose file...' }).click();
  await page.locator('input[type="file"]').setInputFiles(licenseFilePath);
  await page.getByRole('button', { name: 'Connect' }).click();
  await page.getByRole('link', { name: '  Server Logs' }).click();
  await page.getByRole('textbox', { name: 'Start Date' }).click();
  await page.getByRole('button', { name: 'Move backward to switch to' }).dblclick();
  // ✅ รอจนกว่าจะเจอ request ที่ต้องการ

  let matchedRequest = await waitForGetLogsRequest;
  let result;
  matchedRequest.headers = removePseudoHeaders(matchedRequest.headers); // ✅ ลบ pseudo headers
  matchedRequest.body.parameters.fromDate = 0;
  try {
  expect(matchedRequest.body.action).toBe('getLogs');
  // เปลี่ยนค่าที่ต้องการใน matchedRequest.body
matchedRequest.body.parameters.numberOfRowsToReturn = 999999; // ลบเพื่อไม่จำกัดจำนวนแถว
  // ส่ง body ที่แก้ไขไปเลย
  const fetch = require('node-fetch');
  const response = await fetch(matchedRequest.url, {
    method: 'POST',
    headers: matchedRequest.headers,
    body: JSON.stringify(matchedRequest.body)  // <-- ใช้ matchedRequest.body แทน body
  });
  if (!response.ok) {
    console.error(`HTTP Error: ${response.status}`);
    console.log('Response Status:', response.status);
    console.log('Response Status Text:', response.statusText);
    return;
  }
result = await response.json();
 console.log('✅ Matched getLogs request:');
  } catch (error) {
  console.error('Error fetching logs:', error); 
}
  //await saveToMongo(result,'logs','AHA');
  //console.log(util.inspect(result, {showHidden: false, depth: null, maxArrayLength: null}));
  await clipboardy.write(JSON.stringify(result, null, 2));
  console.log('Done to set massage to Clipboard');

});








