const serverlessExpress = require('@vendia/serverless-express');
const app = require('./server');

// Create handler once (outside function for warm starts)
let serverlessExpressInstance;

async function setup() {
  serverlessExpressInstance = serverlessExpress({ app });
  return serverlessExpressInstance;
}

exports.handler = async (event, context) => {
  console.log('Lambda invoked:', JSON.stringify({ event, context }, null, 2));
  
  if (!serverlessExpressInstance) {
    await setup();
  }
  
  return serverlessExpressInstance(event, context);
};
