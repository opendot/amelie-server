echo "Stopping Containers"
docker-compose down

echo "Migrate"
docker-compose run --rm api bin/rails db:migrate RAILS_ENV=development_local

echo "Preprocess personal images"
docker-compose run --rm api bin/rails airett:preprocess_personal_images RAILS_ENV=development_local

echo "Starting Container"
docker-compose up