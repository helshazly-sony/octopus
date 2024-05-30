package main.java;

import java.util.ArrayList;
import java.util.HashSet;
import java.util.List;
import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.CopyOnWriteArrayList;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.stream.Collectors;

import org.apache.arrow.flight.FlightDescriptor;
import org.apache.arrow.flight.FlightEndpoint;
import org.apache.arrow.flight.FlightInfo;
import org.apache.arrow.flight.Location;
import org.apache.arrow.memory.BufferAllocator;
import org.apache.arrow.util.AutoCloseables;
import org.apache.arrow.util.Preconditions;
import org.apache.arrow.vector.dictionary.DictionaryProvider;
import org.apache.arrow.vector.types.pojo.Field;
import org.apache.arrow.vector.types.pojo.Schema;
import org.apache.arrow.vector.util.DictionaryUtility;

import com.google.common.collect.ImmutableList;
import com.google.common.collect.Iterables;

/**
 * A logical collection of streams sharing the same schema.
 */
public class Dataset implements AutoCloseable {

	private final BufferAllocator allocator;
	private final FlightDescriptor descriptor;
	private final Schema schema;
	//private final List<Stream> streams = new CopyOnWriteArrayList<>();
	private final ConcurrentMap<Integer, Stream> streams = new ConcurrentHashMap<>();
	// Atomic counter for ordinals
    private final AtomicInteger ordinalGenerator = new AtomicInteger(0); 
	private final DictionaryProvider dictionaryProvider;
	

	/**
	 * Creates a new instance.
	 * 
	 * @param allocator The allocator to use for allocating buffers to store data.
	 * @param descriptor The descriptor for the streams.
	 * @param schema  The schema for the stream.
	 * @param dictionaryProvider The dictionary provider for the stream.
	 */
	public Dataset(BufferAllocator allocator, FlightDescriptor descriptor, Schema schema,
			DictionaryProvider dictionaryProvider) {
		Preconditions.checkArgument(!descriptor.isCommand());
		this.allocator = allocator.newChildAllocator(descriptor.toString(), 0, Long.MAX_VALUE);
		this.descriptor = descriptor;
		this.schema = schema;
		this.dictionaryProvider = dictionaryProvider;
	}

	/**
	 * Returns the stream based on the ordinal of StreamTicket.
	 */
	public Stream getStream(StreamTicket ticket) {
		//Preconditions.checkArgument(ticket.getOrdinal() < streams.size(), "Unknown stream.");
		//System.out.println("Getting " + ticket.getOrdinal());
		//Stream stream = streams.get(ticket.getOrdinal());
		System.out.println("Removing " + ticket.getOrdinal());
		Stream stream = streams.get(ticket.getOrdinal());
		try{
		   if (ticket.getOrdinal() > 0) {
			streams.remove(ticket.getOrdinal()-1).close();
		   }
		} catch (Exception e) {
			System.out.println("closing: " + e);
		}
		System.out.println("Size = " + streams.size());
		System.out.println(String.join(" ", streams.keySet().toString()));
		stream.verify(ticket);
				
		return stream;
	}

	/**
	 * Adds a new streams which clients can populate via the returned object.
	 */
	public Stream.StreamCreator addStream(Schema schema) {
		Preconditions.checkArgument(this.schema.equals(schema), "Stream schema inconsistent with existing schema.");
		return new Stream.StreamCreator(schema, dictionaryProvider, allocator, t -> {
                        System.out.println("Putting " + ordinalGenerator.get());
			streams.put(ordinalGenerator.getAndIncrement(), t);
		});
	}

	/**
	 * List all available streams as being available at <code>l</code>.
	 */
	public FlightInfo getFlightInfo(final Location l) {
		final long bytes = allocator.getAllocatedMemory();
		final long records = streams.values().stream().collect(Collectors.summingLong(t -> t.getRecordCount()));

		final List<FlightEndpoint> endpoints = new ArrayList<>();
		int i = 0;
		for (Stream s : streams.values()) {
			endpoints.add(
					new FlightEndpoint(
							new StreamTicket(descriptor.getPath(), i, s.getUuid()).toTicket(),
							l));
			i++;
		}
		return new FlightInfo(messageFormatSchema(), descriptor, endpoints, bytes, records);
	}

	private Schema messageFormatSchema() {
		Set<Long> dictionaryIdsUsed = new HashSet<>();
		List<Field> messageFormatFields = schema.getFields()
				.stream()
				.map(f -> DictionaryUtility.toMessageFormat(f, dictionaryProvider, dictionaryIdsUsed))
				.collect(Collectors.toList());
		return new Schema(messageFormatFields, schema.getCustomMetadata());
	}

	@Override
	public void close() throws Exception {
		// Close dictionaries
		final Set<Long> dictionaryIds = new HashSet<>();
		schema.getFields().forEach(field -> DictionaryUtility.toMessageFormat(field, dictionaryProvider, dictionaryIds));

		final Iterable<AutoCloseable> dictionaries = dictionaryIds.stream()
				.map(id -> (AutoCloseable) dictionaryProvider.lookup(id).getVector())::iterator;

		AutoCloseables.close(Iterables.concat(streams.values(), ImmutableList.of(allocator), dictionaries));
	}

	public boolean isEmpty() {
		return this.streams.isEmpty();
	}
}
