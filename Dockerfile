FROM ubuntu:latest
ARG BDS_Version=1.14.1.4

ENV VERSION=$BDS_Version

# Install dependencies, download and extract the bedrock server
RUN apt-get update && \
    apt-get install -y unzip curl libcurl4 libssl1.0.0
    
RUN if [ "$VERSION" = "latest" ] ; then \
        LATEST_VERSION=$( \
            curl -v -S  https://www.minecraft.net/en-us/download/server/bedrock/ 2>&1 | \
            grep -o 'https://minecraft.azureedge.net/bin-linux/[^"]*' | \
            sed 's#.*/bedrock-server-##' | sed 's/.zip//') && \
        VERSION=$LATEST_VERSION && \
        echo "Setting VERSION to $VERSION" ; \
    else echo "Using VERSION of $VERSION"; \
    fi ; \
    echo https://minecraft.azureedge.net/bin-linux/bedrock-server-${VERSION}.zip && \
    curl -v -S https://minecraft.azureedge.net/bin-linux/bedrock-server-${VERSION}.zip --output bedrock-server.zip && \
    unzip bedrock-server.zip -d bedrock-server && \
    rm bedrock-server.zip

# Create a separate folder for configurations move the original files there and create links for the files
RUN mkdir /bedrock-server/config && \
        for f in server.properties permissions.json whitelist.json ; do \
            if [ -f "/bedrock-server/$f" ] ; then \ 
                echo "$f found." && \
                mv "/bedrock-server/$f" /bedrock-server/config && \
                ln -s "/bedrock-server/config/$f" "/bedrock-server/$f" ; \
            else echo "$f not found." ; \
            fi ; \
        done
# If ops.json exists you need to move it for permissions to work.
RUN if [ -f "/bedrock-server/ops.json" ] ; then \ 
        echo "ops.json found." && \
        mv /bedrock-server/ops.json /bedrock-server/config/permissions.json && \
        ln -s /bedrock-server/config/permissions.json /bedrock-server/permissions.json ; \
    else echo "ops.json not found." ; \
    fi 

EXPOSE 19132/udp

VOLUME /bedrock-server/worlds /bedrock-server/config

WORKDIR /bedrock-server
ENV LD_LIBRARY_PATH=.
CMD ./bedrock_server
