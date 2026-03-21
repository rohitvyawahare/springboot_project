# Frontend Dockerfile (Angular + nginx)
FROM node:20-alpine AS build
WORKDIR /workspace

COPY helloworld/package.json helloworld/package-lock.json* ./
COPY helloworld ./

RUN npm ci --silent && npm run build -- --configuration production

# NGINX runtime stage
FROM nginx:stable-alpine
COPY --from=build /workspace/dist/helloworld /usr/share/nginx/html

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
