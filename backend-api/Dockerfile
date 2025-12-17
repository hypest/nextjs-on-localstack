# Use AWS Lambda Node.js base image
FROM public.ecr.aws/lambda/nodejs:18

# Copy package files
COPY package*.json ${LAMBDA_TASK_ROOT}/

# Install production dependencies
RUN npm ci --only=production

# Copy application code
COPY server.js ${LAMBDA_TASK_ROOT}/
COPY lambda-handler.js ${LAMBDA_TASK_ROOT}/

# Set the Lambda handler
CMD [ "lambda-handler.handler" ]