FROM nginx:alpine
COPY index.html /usr/share/nginx/html/index.html
COPY style.css /usr/share/nginx/html/style.css
COPY Task\ 2/ /usr/share/nginx/html/Task\ 2/
COPY Task\ 3/ /usr/share/nginx/html/Task\ 3/
COPY Task\ 4/ /usr/share/nginx/html/Task\ 4/
COPY Task\ 5/ /usr/share/nginx/html/Task\ 5/
COPY Task\ 6/ /usr/share/nginx/html/Task\ 6/
COPY Task\ 7/ /usr/share/nginx/html/Task\ 7/
COPY Task\ 8/ /usr/share/nginx/html/Task\ 8/
COPY Task\ 9/ /usr/share/nginx/html/Task\ 9/
EXPOSE 80
