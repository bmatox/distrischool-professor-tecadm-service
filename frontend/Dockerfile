# =============================================================
# ETAPA 1: Build da Aplicação React
# =============================================================
FROM node:20-alpine AS build

WORKDIR /app

# Copia package.json e package-lock.json
COPY package*.json ./

# Instala as dependências
RUN npm ci --silent

# Copia o código-fonte
COPY . .

# Compila a aplicação
RUN npm run build

# =============================================================
# ETAPA 2: Servir com Nginx
# =============================================================
FROM nginx:alpine

# Copia os arquivos compilados para o nginx
COPY --from=build /app/dist /usr/share/nginx/html

# Copia configuração customizada do nginx (se necessária)
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expõe a porta 80
EXPOSE 80

# Inicia o nginx
CMD ["nginx", "-g", "daemon off;"]
