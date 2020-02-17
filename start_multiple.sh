echo "Stopping Containers"
docker-compose -f docker-compose.multiple.yml down

echo "Migrate"
docker-compose -f docker-compose.multiple.yml run --rm api_local ruby bin/rails db:migrate RAILS_ENV=development_local
docker-compose -f docker-compose.multiple.yml run --rm api_remote ruby bin/rails db:migrate RAILS_ENV=development_remote

echo "Preprocess personal images"
docker-compose -f docker-compose.multiple.yml run --rm api_local ruby bin/rails airett:preprocess_personal_images RAILS_ENV=development_local

echo "Starting Container"
docker-compose -f docker-compose.multiple.yml up