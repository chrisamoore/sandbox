<?php
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class CreateGroupUserTable extends BaseMigration {

	/**
	 * Run the migrations.
	 *
	 * @return void
	 */
	public function up()
	{
		Schema::create("group_user", function(Blueprint $table){
			$this
			    ->setTable($table)
			    ->addPrimary()
			    ->addForeign("group_id")
			    ->addForeign("user_id")
			    ->addTimestamps();
		});
	}

	/**
	 * Reverse the migrations.
	 *
	 * @return void
	 */
	public function down()
	{
        Schema::dropIfExists("group_user");
	}

}
