<?php

	class Group extends Eloquent
	{
		protected $table = 'group';

		protected $softDelete = true;

		protected $guarded = [
			'id',
			'created_at',
			'updated_at',
			'deleted_at'
		];

	}
