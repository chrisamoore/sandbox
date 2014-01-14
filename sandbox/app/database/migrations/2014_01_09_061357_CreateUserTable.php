<?php

    use Illuminate\Database\Schema\Blueprint;
    use Illuminate\Database\Migrations\Migration;

    class CreateUserTable extends BaseMigration {

        /**
         * Run the migrations.
         *
         * @return void
         */
        public function up(){
            Schema::create('user', function (Blueprint $table){
                $table->string("username")->nullable()->default(null);
                $table->string("password")->nullable()->default(null);
                $table->string("email")->nullable()->default(null);
                $table->dateTime("created_at")->nullable()->default(null);
                $table->dateTime("updated_at")->nullable()->default(null);
            });
        }

        /**
         * Reverse the migrations.
         *
         * @return void
         */
        public function down(){
            Schema::dropIfExists("user");
        }

    }
