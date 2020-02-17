echo "Stopping Containers"
docker-compose -f docker-compose.staging_local.yml down

echo "Migrate"
docker-compose -f docker-compose.staging_local.yml run --rm api ruby bin/rails db:migrate RAILS_ENV=staging_local

echo "Preprocess personal images"
docker-compose -f docker-compose.staging_local.yml run --rm api ruby bin/rails airett:preprocess_personal_images RAILS_ENV=staging_local

echo "Starting Container"
docker-compose -f docker-compose.staging_local.yml up