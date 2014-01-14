<?php
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;

class CreateResourceTable extends BaseMigration {

	/**
	 * Run the migrations.
	 *
	 * @return void
	 */
	public function up()
	{
		Schema::create("resource", function(Blueprint $table) {
            $this
                ->setTable($table)
                ->addPrimary()
                ->addString("name")
                ->addString("pattern")
                ->addString("target")
                ->addBoolean("secure")
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
        Schema::dropIfExists("resource");
    }

}
