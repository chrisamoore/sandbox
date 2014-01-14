@extends("layout")

@section("content")

    @if (count($groups))
		<table>
			<tr>
				<th>name</th>
                <th>&nbsp;</th>
			</tr>
		    @foreach ($groups as $group)
				<tr>
					<td>{{ $group->name }}</td>
					<td>
						<a href="{{ URL::route('group/edit') }}?id={{ $group->id }}">edit</a>
						<a href="{{ URL::route('group/delete') }}?id={{ $group->id}}" class="confirm" data-confirm="Areyousureyouwanttodeletethisgroup?">delete</a>
					</td>
				</tr>
			@endforeach
		</table>
	@else
		<p>There are no groups.</p>
	@endif

	<a href="{{ URL::route("group/add") }}">add group</a>
@stop


@section("footer")
    @parent
	<script src="/js/jquery.js"></script>
	<script src="/js/layout.js"></script>
@stop
