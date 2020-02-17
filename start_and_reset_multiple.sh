echo "Stopping Containers"
docker-compose -f docker-compose.multiple.yml down

echo "Set environment"
docker-compose -f docker-compose.multiple.yml run --rm api_local ruby bin/rails db:environment:set RAILS_ENV=development_local
docker-compose -f docker-compose.multiple.yml run --rm api_remote ruby bin/rails db:environment:set RAILS_ENV=development_remote

echo "Drop the database"
docker-compose -f docker-compose.multiple.yml run --rm api_local ruby bin/rails db:drop RAILS_ENV=development_local
docker-compose -f docker-compose.multiple.yml run --rm api_remote ruby bin/rails db:drop RAILS_ENV=development_remote

echo "Create the database"
docker-compose -f docker-compose.multiple.yml run --rm api_local ruby bin/rails db:create RAILS_ENV=development_local
docker-compose -f docker-compose.multiple.yml run --rm api_remote ruby bin/rails db:create RAILS_ENV=development_remote

echo "Migrate"
docker-compose -f docker-compose.multiple.yml run --rm api_local ruby bin/rails db:migrate RAILS_ENV=development_local
docker-compose -f docker-compose.multiple.yml run --rm api_remote ruby bin/rails db:migrate RAILS_ENV=development_remote

echo "Seed"
docker-compose -f docker-compose.multiple.yml run --rm api_local ruby bin/rails db:seed RAILS_ENV=development_local
docker-compose -f docker-compose.multiple.yml run --rm api_remote ruby bin/rails db:seed RAILS_ENV=development_remote

echo "Preprocess personal images"
docker-compose -f docker-compose.multiple.yml run --rm api_local ruby bin/rails airett:preprocess_personal_images RAILS_ENV=development_local

echo "Starting Container"
docker-compose -f docker-compose.multiple.yml up