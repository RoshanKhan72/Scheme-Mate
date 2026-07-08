const swaggerJsdoc = require('swagger-jsdoc');
require('dotenv').config();

const PORT = process.env.PORT || 5000;

const options = {
  definition: {
    openapi: '3.0.0',
    info: {
      title: 'Scheme Mate - Authentication API',
      version: '1.0.0',
      description: 'API Documentation for the Authentication module of Scheme Mate.',
      contact: {
        name: 'Developer Support',
      },
    },
    servers: [
      {
        url: `http://localhost:${PORT}`,
        description: 'Local Development Server',
      },
    ],
    components: {
      securitySchemes: {
        bearerAuth: {
          type: 'http',
          scheme: 'bearer',
          bearerFormat: 'JWT',
          description: 'Enter your JWT token in the format: Bearer <token>',
        },
      },
    },
  },
  // Paths to files containing OpenAPI JSDoc annotations
  apis: ['./src/routes/*.js', './src/controllers/*.js'],
};

const swaggerSpec = swaggerJsdoc(options);

module.exports = swaggerSpec;
