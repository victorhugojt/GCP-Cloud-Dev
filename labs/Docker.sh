cat > Dockerfile <<EOF
# Use an official Node runtime as the parent image
FROM node:lts

# Set the working directory in the container to /app
WORKDIR /app

# Copy the current directory contents into the container at /app
ADD . /app

# Make the container's port 80 available to the outside world
EXPOSE 80

# Run app.js using node when the container launches
CMD ["node", "app.js"]
EOF

cat > app.js << EOF;
const http = require("http");

const hostname = "0.0.0.0";
const port = 80;

const server = http.createServer((req, res) => {
	res.statusCode = 200;
	res.setHeader("Content-Type", "text/plain");
	res.end("Hello World\n");
});

server.listen(port, hostname, () => {
	console.log("Server running at http://%s:%s/", hostname, port);
});

process.on("SIGINT", function () {
	console.log("Caught interrupt signal and will exit");
	process.exit();
});
EOF

docker images

docker run -p 4000:80 --name my-app node-app:0.1

curl http://localhost:4000

docker stop my-app && docker rm my-app

docker run -p 4000:80 --name my-app node-app:0.1

docker ps

docker logs b6c49a02d3c3

docker logs -f 29d7d3d3ce62

docker exec -it 29d7d3d3ce62 bash

docker exec -it my-app bash

docker exec -it my-app ls -l

docker exec -it my-app pwd

docker exec -it my-app cat /app/app.js

docker exec -it my-app cat /app/package.json

exit
docker inspect 29d7d3d3ce62

docker inspect my-app

docker inspect b6c49a02d3c3

docker inspect 29d7d3d3ce62

docker inspect my-app

docker inspect b6c49a02d3c3

docker inspect --format='{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' 29d7d3d3ce62

gcloud auth configure-docker us-west1-docker.pkg.dev

gcloud artifacts repositories create my-repository --repository-format=docker --location=us-west1 --description="Docker repository"


docker stop $(docker ps -q)
docker rm $(docker ps -aq)

docker rmi us-west1-docker.pkg.dev/qwiklabs-gcp-00-1d92cfdc5a39/my-repository/node-app:0.2
docker rmi node:lts
docker rmi -f $(docker images -aq) # remove remaining images
docker images